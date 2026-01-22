const RECORD_BUTTON = document.querySelector('#voice_btn');

// File-specific variables for recording
let recognition = null;
let is_recording = false;

// Check that the user's browser supports speech recognition - if not, don't do anything and 
// disable this functionality:
if ('SpeechRecognition' in window || 'webkitSpeechRecognition' in window) {
    let speech_rec = window.SpeechRecognition || window.webkitSpeechRecognition
    recognition = new SpeechRecognition
    recognition.continuous = false;
    recognition.interimResults = true;
    recognition.lang = 'en-US';

    recognition.onevent = (event) => {
        let transcript = '';
        for (let i = event.resultIndex; i < event.results.length; i++) {
            transcript += event.results[i][0].transcript;
        }
        USER_INPUT.value = transcript;
        update_button_state();
    }

    recognition.onerror = (event) => {
        console.error(`Unable to recognize speech: ${event}`);
        stop_recording();
        alert("Voice recognition failed.  Please try again or type your message!");
    }

    recognition.onend = () => {
        stop_recording()
    }
} else {
    RECORD_BUTTON.style.display = 'none';
}

// -- Helper functions --
const start_recording = () => {
    if (!recognition || is_recording) return;
    is_recording = true;
    RECORD_BUTTON.classList.add('recording');
    recognition.start();
}

const stop_recording = () => {
    if (!recognition) return;
    is_recording = false;
    RECORD_BUTTON.classList.remove('recording');
    recognition?.stop();
}

// Then, add event listeners for the audio button - we want to record when the button 
// is held down:
let hold_timeout;
RECORD_BUTTON.addEventListener('mousedown', start_recording);
RECORD_BUTTON.addEventListener('touchstart', (e) => {
    e.preventDefault();
    start_recording();
});
RECORD_BUTTON.addEventListener('mouseup', stop_recording);
RECORD_BUTTON.addEventListener('touchend', stop_recording);
RECORD_BUTTON.addEventListener('mouseleave', stop_recording);