// *** ADD THIS LINE TO THE VERY TOP ***
/// <reference types="firebase-admin/firestore" />
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp, FieldValue, DocumentReference } from "firebase-admin/firestore";

initializeApp();
const db = getFirestore();
const REGION = "asia-southeast1";

const snapWithId = <T extends Record<string, any>>(s: FirebaseFirestore.DocumentSnapshot): T & { id: string } =>
  ({ id: s.id, ...(s.data() as any) });

export const getPackageById = onCall({ region: REGION }, async (req) => {
// ... (existing functions getPackageById, listPackages, etc. are here)
// ...

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

// **********************************************
// ********* PACKAGE CREATION FUNCTIONS *********
// **********************************************

// Interface สำหรับข้อมูลที่อยู่ (Addresses)
interface AddressData {
  address_text: string;
  latitude: number;
  longitude: number;
}

// Interface สำหรับข้อมูลสินค้าแต่ละรายการ (Images)
interface ItemData {
  description: string;
  proof_image_url: string; // URL ที่ได้จากการอัปโหลดไป Firebase Storage ก่อนหน้านี้
}

/**
 * สร้างรายการส่งสินค้าใหม่ (Package) พร้อมบันทึกที่อยู่และรายละเอียดสินค้า
 */
export const createPackage = onCall({ region: REGION }, async (req) => {
  // ตรวจสอบ Authentication (ผู้ใช้ต้อง Login ก่อน)
  if (!req.auth) throw new HttpsError("unauthenticated", "Login required to create a package.");

  const {
    senderAddress,
    receiverAddress,
    items,
    pkgDescription = "", // รายละเอียดรวมของ package
  } = req.data || {};

  const senderId = req.auth.uid; // ใช้ UID ของผู้ที่เรียกฟังก์ชันเป็น senderId

  // 1. ตรวจสอบ Argument
  if (!receiverAddress || typeof receiverAddress !== 'object') {
    throw new HttpsError("invalid-argument", "receiverAddress (AddressData) is required.");
  }
  if (!Array.isArray(items) || items.length === 0) {
    throw new HttpsError("invalid-argument", "items (Array of ItemData) required, min 1 item.");
  }
  
  // ตรวจสอบความสมบูรณ์ของข้อมูลที่อยู่
  const validateAddress = (addr: any) => {
    return addr && typeof addr.address_text === 'string' && typeof addr.latitude === 'number' && typeof addr.longitude === 'number';
  }

  if (!validateAddress(receiverAddress)) {
      throw new HttpsError("invalid-argument", "Invalid receiverAddress format.");
  }
  if (senderAddress && !validateAddress(senderAddress)) {
      throw new HttpsError("invalid-argument", "Invalid senderAddress format.");
  }

  // ตรวจสอบความสมบูรณ์ของข้อมูลสินค้า
  for (const item of items) {
      if (typeof item.description !== 'string' || typeof item.proof_image_url !== 'string') {
          throw new HttpsError("invalid-argument", "Invalid item data format (description/proof_image_url).");
      }
  }

  // กำหนดชนิดให้ packageRef เป็น DocumentReference ที่ถูกต้อง
  let packageRef: DocumentReference | null = null;
  let senderAddressId: string | undefined = undefined;
  let receiverAddressId: string;

  try {
    // 2. ใช้ Transaction
    await db.runTransaction(async (t) => {
      // 2.1 บันทึกที่อยู่ผู้ส่ง
      if (senderAddress) {
        const newSenderAddressRef = db.collection("addresses").doc();
        t.set(newSenderAddressRef, { ...senderAddress, user_id: senderId });
        senderAddressId = newSenderAddressRef.id;
      }
      
      // 2.2 บันทึกที่อยู่ผู้รับ
      const newReceiverAddressRef = db.collection("addresses").doc();
      t.set(newReceiverAddressRef, { ...receiverAddress, user_id: null }); 
      receiverAddressId = newReceiverAddressRef.id;


      // 2.3 สร้าง Package
      packageRef = db.collection("packages").doc();
      const newPackageData = {
        package_id: packageRef.id,
        sender_id: senderId, 
        addsender: senderAddressId, 
        addreceiver: receiverAddressId, 
        current_status: "Awaiting Rider", 
        created_at: Timestamp.now(),
        rider_id: null,
        description: pkgDescription,
      };
      t.set(packageRef, newPackageData);
    }); 

    // 3. บันทึก Sub-collection Images
    if (packageRef) {
      const batch = db.batch();
      for (const item of items as ItemData[]) {
        const imageRef = packageRef.collection("images").doc();
        const imageId = imageRef.id;
        batch.set(imageRef, {
          img_id: imageId,
          package_id: packageRef.id,
          proof_image_url: item.proof_image_url,
          status_img: "Attached", 
          description: item.description, 
        });
      }
      await batch.commit();
    }


    // 4. ดึงข้อมูลกลับ
    if (packageRef) {
      const snap = await packageRef.get();
      return snapWithId(snap);
    }
    
    throw new HttpsError("internal", "Failed to finalize package creation.");

  } catch (error) {
    console.error("Error creating package:", error);
    if (error instanceof HttpsError) throw error;
    throw new HttpsError("internal", "An unexpected error occurred during package creation.");
  }
});