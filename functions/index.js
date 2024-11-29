const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp({
    credential: admin.credential.cert(require('./serviceAccountKey.json'))
});

const { signInWithGoogle } = require('./authGoogleUser');
const { endAuction } = require('./endAuction');
const { submitSurvey } = require('./sendSubmit');
const { getUserInfo } = require('./getUserInfo');

exports.signInWithGoogle = signInWithGoogle;
exports.endAuction = endAuction;
exports.submitSurvey = submitSurvey;
exports.getUserInfo = getUserInfo;