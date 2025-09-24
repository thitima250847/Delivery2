import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();
const REGION = "asia-southeast1";

const snapWithId = <T extends Record<string, any>>(s: FirebaseFirestore.DocumentSnapshot): T & { id: string } =>
  ({ id: s.id, ...(s.data() as any) });

export const getPackageById = onCall({ region: REGION }, async (req) => {
  const { packageId } = req.data || {};
  if (!packageId) throw new HttpsError("invalid-argument", "packageId is required");

  const pkgDoc = await db.collection("packages").doc(packageId).get();
  if (!pkgDoc.exists) throw new HttpsError("not-found", "package not found");
  const pkg = snapWithId(pkgDoc);

  let sender: any = null, receiver: any = null;
  if (pkg.sender_id) {
    const s = await db.collection("users").doc(pkg.sender_id).get().catch(() => null);
    if (s?.exists) sender = snapWithId(s);
  }
  if (pkg.receiver_id) {
    const r = await db.collection("users").doc(pkg.receiver_id).get().catch(() => null);
    if (r?.exists) receiver = snapWithId(r);
  }

  let addressFrom: any = null, addressTo: any = null;
  if (pkg.addsender) {
    const a = await db.collection("addresses").doc(pkg.addsender).get().catch(() => null);
    if (a?.exists) addressFrom = snapWithId(a);
  }
  if (pkg.addreceiver) {
    const a = await db.collection("addresses").doc(pkg.addreceiver).get().catch(() => null);
    if (a?.exists) addressTo = snapWithId(a);
  }

  let rider: any = null;
  if (pkg.rider_id) {
    const r = await db.collection("riders").doc(pkg.rider_id).get().catch(() => null);
    if (r?.exists) rider = snapWithId(r);
  }

  const imgsSnap = await db.collection("packages").doc(packageId).collection("images").get();
  const images = imgsSnap.docs.map((d) => snapWithId(d));

  return { package: pkg, sender, receiver, address_from: addressFrom, address_to: addressTo, rider, images };
});

export const listPackages = onCall({ region: REGION }, async (req) => {
  const { status, limit = 50 } = req.data || {};
  let q = db.collection("packages") as FirebaseFirestore.Query;
  if (status) q = q.where("current_status", "==", status);
  q = q.orderBy("created_at", "desc").limit(Math.min(Number(limit) || 50, 100));
  const snap = await q.get();
  return snap.docs.map((d) => snapWithId(d));
});

export const listAssignedPackages = onCall({ region: REGION }, async (req) => {
  const { riderId, limit = 50 } = req.data || {};
  if (!riderId) throw new HttpsError("invalid-argument", "riderId is required");
  const q = db.collection("packages")
    .where("rider_id", "==", riderId)
    .orderBy("created_at", "desc")
    .limit(Math.min(Number(limit) || 50, 100));
  const snap = await q.get();
  return snap.docs.map((d) => snapWithId(d));
});

export const setRiderAvailability = onCall({ region: REGION }, async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Login required");
  const { available } = req.data || {};
  if (typeof available !== "boolean") throw new HttpsError("invalid-argument", "available:boolean required");
  await db.collection("riders").doc(req.auth.uid).set({ is_available: available }, { merge: true });
  return { ok: true };
});

export const updateRiderLocation = onCall({ region: REGION }, async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Login required");
  const { lat, lng } = req.data || {};
  if (typeof lat !== "number" || typeof lng !== "number") {
    throw new HttpsError("invalid-argument", "lat/lng:number required");
  }
  await db.collection("riders").doc(req.auth.uid).set({
    current_latitude: lat,
    current_longitude: lng,
    location_updated_at: FieldValue.serverTimestamp()
  }, { merge: true });
  return { ok: true };
});

export const registerRider = onCall({ region: REGION }, async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Login required");
  const { name, licensePlate } = req.data || {};
  if (!name || !licensePlate) throw new HttpsError("invalid-argument", "name, licensePlate required");

  const uid = req.auth.uid;
  await db.collection("riders").doc(uid).set({
    user_id: uid,
    name,
    license_plate: licensePlate,
    is_available: false,
    current_latitude: null,
    current_longitude: null,
    created_at: Timestamp.now()
  }, { merge: true });

  const snap = await db.collection("riders").doc(uid).get();
  return snapWithId(snap);
});
