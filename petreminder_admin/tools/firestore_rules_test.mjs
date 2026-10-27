import { readFile } from 'node:fs/promises';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import {
  collection,
  collectionGroup,
  doc,
  getDoc,
  getDocs,
  setDoc,
  updateDoc,
  deleteDoc,
  serverTimestamp,
  writeBatch,
  query,
  where,
} from 'firebase/firestore';

const projectId = 'demo-petreminder-tests';
const rules = await readFile(new URL('../../firestore.rules', import.meta.url), 'utf8');
const environment = await initializeTestEnvironment({
  projectId,
  firestore: { rules },
});

const userData = (uid, status = 'active') => ({
  uid,
  name: uid === 'owner' ? 'Usuario Prueba' : 'Otro Usuario',
  email: `${uid}@example.com`,
  photoUrl: null,
  createdAt: new Date('2026-01-01T00:00:00Z'),
  lastActivity: new Date('2026-01-01T00:00:00Z'),
  accountStatus: status,
});

const petData = {
  name: 'Max',
  nameKey: 'max',
  species: 'Perro',
  breed: '',
  age: 3,
  description: '',
  photoUrl: null,
  createdAt: new Date('2026-01-01T00:00:00Z'),
};

try {
  await environment.clearFirestore();
  await environment.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/owner'), userData('owner'));
    await setDoc(doc(db, 'users/disabled'), userData('disabled', 'disabled'));
    await setDoc(doc(db, 'users/other'), userData('other'));
    await setDoc(doc(db, 'users/owner/pets/max'), petData);
    await setDoc(doc(db, 'users/owner/petNames/max'), {petIds:['max']});
    await setDoc(doc(db, 'users/other/pets/luna'), {
      ...petData,
      name: 'Luna', nameKey: 'luna',
      species: 'Gato',
    });
  });

  const guest = environment.unauthenticatedContext().firestore();
  const pendingOwner = environment.authenticatedContext('owner', {
    email: 'owner@example.com', email_verified: false,
  }).firestore();
  const pendingAdmin = environment.authenticatedContext('admin', {
    admin: true, email: 'admin@example.com', email_verified: false,
  }).firestore();
  await assertFails(getDoc(doc(pendingOwner, 'users/owner/pets/max')));
  await assertFails(getDocs(collection(pendingOwner, 'users/owner/pets')));
  await assertFails(setDoc(doc(pendingOwner, 'users/owner/pets/blocked'), petData));
  await assertFails(getDoc(doc(pendingAdmin, 'users/owner')));
  await assertFails(getDoc(doc(pendingOwner, 'emailVerificationPrivate/owner')));
  await assertFails(setDoc(doc(pendingOwner, 'emailVerificationPrivate/owner'), { code: '12345' }));
  await assertFails(getDoc(doc(pendingOwner, 'emailVerificationLimits/global')));
  const owner = environment
    .authenticatedContext('owner', { email: 'owner@example.com', email_verified: true })
    .firestore();
  const disabled = environment
    .authenticatedContext('disabled', { email: 'disabled@example.com', email_verified: true })
    .firestore();
  const admin = environment
    .authenticatedContext('admin', { admin: true, email: 'admin@example.com', email_verified: true })
    .firestore();

  await assertFails(getDoc(doc(guest, 'users/owner')));
  await assertSucceeds(getDoc(doc(owner, 'users/owner')));
  await assertFails(getDoc(doc(owner, 'users/other')));
  await assertFails(getDocs(collection(owner, 'users')));
  await assertSucceeds(getDoc(doc(owner, 'users/owner/pets/max')));
  await assertFails(getDoc(doc(owner, 'users/other/pets/luna')));
  await assertFails(getDocs(collectionGroup(owner, 'pets')));
  await assertFails(getDoc(doc(disabled, 'users/disabled/pets/any')));
  await assertFails(
    updateDoc(doc(owner, 'users/owner'), { accountStatus: 'disabled' }),
  );

  await assertSucceeds(getDocs(collection(admin, 'users')));
  await assertSucceeds(getDocs(collectionGroup(admin, 'pets')));
  const limits = {Perro: 30, Gato: 30, Conejo: 20, Ave: 100, 'Hámster': 5, Tortuga: 200, Pez: 100, Otro: 250};
  for (const [species, maxAge] of Object.entries(limits)) {
    const target = doc(owner, `users/owner/pets/limits-${species}`);
    const name = `Mascota ${species === 'Otro' ? 'Otra' : species}`;
    const data = {...petData, name, nameKey:name.toLowerCase(), species, age: maxAge, ageMonths: 0,
      customSpecies: species === 'Otro' ? 'Hurón' : '', createdAt: serverTimestamp()};
    const create = writeBatch(owner);
    create.set(target, data);
    create.set(doc(owner, `users/owner/petNames/${data.nameKey}`), {petIds:[target.id]});
    await assertSucceeds(create.commit());
    await assertFails(updateDoc(target, {ageMonths: 1}));
    await assertFails(updateDoc(target, {age: -1}));
    await assertFails(updateDoc(target, {age: 0, ageMonths: 12}));
    await assertSucceeds(updateDoc(target, {age: 0, ageMonths: 11}));
    await assertFails(updateDoc(target, {name: 'a'}));
    await assertFails(updateDoc(target, {name: 'a'.repeat(61)}));
    await assertFails(updateDoc(target, {breed: 'a'.repeat(81)}));
    await assertFails(updateDoc(target, {description: 'a'.repeat(501)}));
  }

  // No se puede saltar la reserva, apropiarse de un nombre ni liberar uno ajeno.
  await assertFails(setDoc(doc(owner, 'users/owner/pets/duplicate'), {...petData, createdAt:serverTimestamp()}));
  const steal = writeBatch(owner);
  steal.set(doc(owner, 'users/owner/pets/duplicate'), {...petData, createdAt:serverTimestamp()});
  steal.set(doc(owner, 'users/owner/petNames/max'), {petIds:['duplicate']});
  await assertFails(steal.commit());
  await assertFails(deleteDoc(doc(owner, 'users/owner/petNames/max')));
  await assertFails(deleteDoc(doc(owner, 'users/owner/pets/max')));
  await assertFails(updateDoc(doc(owner, 'users/owner/pets/max'), {name:'Toby', nameKey:'toby'}));
  // Dos escrituras simultáneas: solo una obtiene la reserva.
  async function compete(id) {
    const batch = writeBatch(owner);
    batch.set(doc(owner, `users/owner/pets/${id}`), {...petData, name:'Nube', nameKey:'nube', createdAt:serverTimestamp()});
    batch.set(doc(owner, 'users/owner/petNames/nube'), {petIds:[id]});
    return batch.commit();
  }
  const competition = await Promise.allSettled([compete('concurrent-a'), compete('concurrent-b')]);
  if (competition.filter(r => r.status === 'fulfilled').length !== 1) throw new Error('La reserva concurrente no fue única');
  const reservation = (await getDoc(doc(owner, 'users/owner/petNames/nube'))).data();
  const winner = reservation.petIds[0];
  const rename = writeBatch(owner);
  rename.update(doc(owner, `users/owner/pets/${winner}`), {name:'Brisa', nameKey:'brisa'});
  rename.delete(doc(owner, 'users/owner/petNames/nube'));
  rename.set(doc(owner, 'users/owner/petNames/brisa'), {petIds:[winner]});
  await assertSucceeds(rename.commit());
  const remove = writeBatch(owner);
  remove.delete(doc(owner, `users/owner/pets/${winner}`));
  remove.delete(doc(owner, 'users/owner/petNames/brisa'));
  await assertSucceeds(remove.commit());

  const schedule = doc(owner, 'users/owner/pets/max/feedingSchedules/s');
  await assertSucceeds(setDoc(schedule, {id:'s', time:'08:00', active:true, createdAt:serverTimestamp()}));
  await assertFails(setDoc(doc(owner, 'users/owner/pets/missing/feedingSchedules/s'),
    {id:'s', time:'08:00', active:true, createdAt:serverTimestamp()}));
  const historyData = {id:'meal', userId:'owner', petId:'max', petName:'Max',
    scheduleId:'s', scheduledTime:'08:00', dateKey:'2026-10-20', status:'pending', fedAt:null, createdAt:serverTimestamp()};
  const meal = doc(owner,'users/owner/feedingHistory/meal');
  await assertSucceeds(setDoc(meal,historyData));
  await assertSucceeds(updateDoc(meal,{scheduledTime:'09:00'}));
  await assertSucceeds(updateDoc(meal,{status:'fed',fedAt:serverTimestamp()}));
  await assertFails(updateDoc(meal,{scheduledTime:'10:00'}));
  await deleteDoc(schedule);
  await assertFails(setDoc(doc(owner,'users/owner/feedingHistory/removed'),
    {...historyData,id:'removed'}));
  // Nuevas validaciones y compatibilidad de documentos de la beta anterior.
  await assertFails(updateDoc(doc(owner, 'users/owner'), {name:'Persona123'}));
  await assertSucceeds(updateDoc(doc(owner, 'users/owner'), {name:'María José'}));
  const newSchedule = doc(owner,'users/owner/pets/max/feedingSchedules/new');
  const scheduleData = {id:'new',time:'12:30',active:true,createdAt:serverTimestamp(),
    label:'Comida',foodType:'Croquetas',notes:'Revisar el agua',weekdays:[1,3,5]};
  await assertSucceeds(setDoc(newSchedule,scheduleData));
  await assertFails(updateDoc(newSchedule,{weekdays:[]}));
  await assertFails(updateDoc(newSchedule,{weekdays:[1,1]}));
  await assertFails(updateDoc(newSchedule,{weekdays:[0,8]}));
  const plan = doc(owner,'users/owner/pets/max/carePlan/diet');
  await assertSucceeds(setDoc(plan,{dailyGrams:150,weightKg:5,mealsPerDay:3,food:'Alimento',notes:''}));
  await assertFails(updateDoc(plan,{dailyGrams:-1}));
  await assertFails(updateDoc(plan,{mealsPerDay:0}));
  const medicalData = {title:'Revisión anual',kind:'Consulta',date:new Date(),notes:'Registro de prueba',nextDate:null};
  await assertSucceeds(setDoc(doc(owner,'users/owner/pets/max/medicalRecords/visit'),medicalData));
  await assertFails(setDoc(doc(owner,'users/owner/pets/missing/medicalRecords/visit'),medicalData));
  const manualData = {...historyData,id:'manual',scheduleId:'manual',manual:true,status:'fed',grams:50,
    food:'Croquetas',fedAt:serverTimestamp()};
  await assertSucceeds(setDoc(doc(owner,'users/owner/feedingHistory/manual'),manualData));
  await assertFails(setDoc(doc(owner,'users/owner/feedingHistory/invalid-manual'),{...manualData,id:'invalid-manual',grams:-1}));
  await assertFails(updateDoc(doc(owner,'users/owner/feedingHistory/manual'),{grams:999}));

  // Cuidado compartido: una cuenta ajena no puede concederse acceso por sí sola.
  const member = environment.authenticatedContext('other',{email:'other@example.com',email_verified:true}).firestore();
  const unverified = environment.authenticatedContext('other',{email:'other@example.com',email_verified:false}).firestore();
  const wrongEmail = environment.authenticatedContext('other',{email:'wrong@example.com',email_verified:true}).firestore();
  const invite = doc(owner,'careInvitations/family');
  const invitationData = {ownerId:'owner',ownerName:'María José',email:'other@example.com',status:'pending',acceptedBy:null,createdAt:serverTimestamp()};
  await assertSucceeds(setDoc(invite,invitationData));
  await assertSucceeds(getDocs(query(collection(owner,'careInvitations'),where('ownerId','==','owner'))));
  await assertSucceeds(getDocs(query(collection(member,'careInvitations'),where('email','==','other@example.com'))));
  await assertFails(getDocs(collection(member,'careInvitations')));
  await assertFails(getDoc(doc(unverified,'careInvitations/family')));
  await assertFails(getDoc(doc(wrongEmail,'careInvitations/family')));
  await assertSucceeds(getDoc(doc(member,'careInvitations/family')));
  await assertFails(setDoc(doc(member,'users/owner/caregivers/other'),{uid:'other',email:'other@example.com',invitationId:'family',createdAt:serverTimestamp()}));
  await assertFails(getDoc(doc(member,'users/owner/pets/max')));
  const accept = writeBatch(member);
  accept.update(doc(member,'careInvitations/family'),{status:'accepted',acceptedBy:'other'});
  accept.set(doc(member,'users/owner/caregivers/other'),{uid:'other',email:'other@example.com',invitationId:'family',createdAt:serverTimestamp()});
  accept.set(doc(member,'users/other/careSpaces/owner'),{ownerId:'owner',ownerName:'María José',invitationId:'family'});
  await assertSucceeds(accept.commit());
  await assertSucceeds(getDoc(doc(member,'users/owner/pets/max')));
  await assertSucceeds(getDocs(collection(member,'users/owner/pets')));
  await assertSucceeds(getDocs(collection(member,'users/owner/feedingHistory')));
  await assertSucceeds(updateDoc(doc(member,'users/owner/pets/max/carePlan/diet'),{dailyGrams:200}));
  await assertSucceeds(setDoc(doc(member,'users/owner/pets/max/medicalRecords/family'),medicalData));
  await assertSucceeds(updateDoc(doc(member,'users/owner/pets/max/feedingSchedules/new'),{time:'13:00'}));
  await assertFails(getDoc(doc(member,'users/owner')));
  await assertFails(updateDoc(doc(member,'users/owner'),{accountStatus:'disabled'}));
  await assertFails(setDoc(doc(member,'users/owner/caregivers/intruder'),{uid:'intruder'}));
  await assertFails(getDoc(doc(member,'users/disabled/pets/any')));
  await assertSucceeds(updateDoc(invite,{status:'revoked'}));
  await assertFails(getDoc(doc(member,'users/owner/pets/max')));
  await assertFails(updateDoc(doc(member,'users/owner/pets/max/carePlan/diet'),{dailyGrams:300}));
  await assertFails(setDoc(doc(member,'users/owner/caregivers/other'),{uid:'other',email:'other@example.com',invitationId:'family',createdAt:serverTimestamp()}));
  await assertSucceeds(deleteDoc(doc(owner,'users/owner/caregivers/other')));
  await assertSucceeds(
    updateDoc(doc(admin, 'users/owner'), { accountStatus: 'disabled' }),
  );
  await assertFails(updateDoc(doc(admin, 'users/other'), { name: 'Cambio' }));
  await assertFails(setDoc(doc(admin, 'users/other/pets/new'), petData));

  console.log('Firestore rules: todas las pruebas pasaron.');
} finally {
  await environment.cleanup();
}
