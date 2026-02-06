// =======================================================
// IMPORTS
// =======================================================
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// =======================================================
// 🔔 MAIN SOS TRIGGER (CORE OF YOUR SYSTEM)
// =======================================================
exports.onSosCreated = functions.firestore
  .document("sos_alerts/{sosId}")
  .onCreate(async (snap, context) => {
    try {
      const sos = snap.data();

      if (!sos || !sos.userId || !sos.source) {
        console.log("❌ Invalid SOS payload");
        return null;
      }

      const userId = sos.userId;
      const source = sos.source; // manual | voice | ai
      const dangerScore = sos.risk ?? null; // default full risk
      const latitude = sos.latitude;
      const longitude = sos.longitude;

      console.log("🚨 SOS RECEIVED:", sos);

      // ===================================================
      // 1️⃣ FETCH USER DETAILS
      // ===================================================
      const userDoc = await db.collection("users").doc(userId).get();
      const userName = userDoc.exists
        ? userDoc.data().name || "User"
        : "User";

      // ===================================================
      // 2️⃣ FETCH GUARDIAN TOKENS
      // ===================================================
      const guardianSnap = await db
        .collection("guardians")
        .where("linkedUserId", "==", userId)
        .get();

      const guardianTokens = guardianSnap.docs
        .map((doc) => doc.data().fcmToken)
        .filter(Boolean);

      // ===================================================
      // 3️⃣ FETCH AUTHORITY TOKENS
      // ===================================================
      const authoritySnap = await db
        .collection("authorities")
        .where("active", "==", true)
        .get();

      const authorityTokens = authoritySnap.docs
        .map((doc) => doc.data().fcmToken)
        .filter(Boolean);

      // ===================================================
      // 4️⃣ DECIDE WHO TO NOTIFY (YOUR LOGIC)
      // ===================================================
      let notifyGuardians = true;
      let notifyAuthorities = false;

      if (source === "manual" || source === "voice") {
        notifyAuthorities = true;
      }

      if (source === "ai" && dangerScore >= 90) {
        notifyAuthorities = true;
      }

      // ===================================================
      // 5️⃣ BUILD NOTIFICATION PAYLOAD
      // ===================================================
      const notificationPayload = {
        notification: {
          title: "🚨 LYRA SOS ALERT",
          body:
              source === "ai"
                ? `AI detected high danger`
                : source === "voice"
                ? `Voice SOS triggered`
                : `Manual SOS triggered`,

        },
    data: {
  source,
  risk: dangerScore ? dangerScore.toString() : "",
  latitude: latitude?.toString() || "",
  longitude: longitude?.toString() || "",
  userId,
},
          
      };

      // ===================================================
      // 6️⃣ SEND TO GUARDIANS
      // ===================================================
      if (notifyGuardians && guardianTokens.length > 0) {
        await messaging.sendEachForMulticast({
          tokens: guardianTokens,
          ...notificationPayload,
        });

        console.log("✅ Guardian notifications sent");
      }

      // ===================================================
      // 7️⃣ SEND TO AUTHORITIES
      // ===================================================
      if (notifyAuthorities && authorityTokens.length > 0) {
        await messaging.sendEachForMulticast({
          tokens: authorityTokens,
          ...notificationPayload,
        });

        console.log("🚓 Authority notifications sent");
      }

      // ===================================================
      // 8️⃣ LOG DELIVERY
      // ===================================================
      await db.collection("notification_logs").add({
        sosId: context.params.sosId,
        userId,
        source,
        dangerScore,
        guardiansNotified: notifyGuardians,
        authoritiesNotified: notifyAuthorities,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;

    } catch (error) {
      console.error("🔥 SOS FUNCTION ERROR:", error);
      return null;
    }
  });
  exports.onTrackingStarted = functions.firestore
  .document("tracking_events/{eventId}")
  .onCreate(async (snap, context) => {
    try {
      const event = snap.data();
      if (!event || event.type !== "started") return null;

      const userId = event.userId;

      // 1️⃣ Get user name
      const userDoc = await db.collection("users").doc(userId).get();
      const userName = userDoc.exists
        ? userDoc.data().Name || "User"
        : "User";

      // 2️⃣ Get guardian FCM tokens
      const guardianSnap = await db
        .collection("guardians")
        .where("linkedUserId", "==", userId)
        .get();

      const tokens = guardianSnap.docs
        .map(doc => doc.data().fcmToken)
        .filter(Boolean);

      if (tokens.length === 0) return null;

      // 3️⃣ Tracking link
      const liveLink = `https://lyra-tracking.web.app/?user=${userId}`;

      // 4️⃣ Notification payload
      const payload = {
        notification: {
          title: "📍 Live Tracking Started",
          body: `${userName} started live tracking. Tap to view location.`,
        },
        data: {
          type: "tracking",
          userId,
          link: liveLink,
        },
      };

      // 5️⃣ Send notification
      await messaging.sendEachForMulticast({
        tokens,
        ...payload,
      });

      console.log("✅ Tracking notification sent");

      return null;
    } catch (e) {
      console.error("🔥 Tracking error:", e);
      return null;
    }
  });
