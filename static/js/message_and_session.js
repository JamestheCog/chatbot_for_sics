/*
*   A JavaScript file to contain the JavaScript for sending and receiving output 
*   from the application's backend - plus managing user sessions.
*/

// --- HTML elements of interest ---
const SEND_BUTTON = document.querySelector('#send_button');
const MESSAGES = document.querySelector('#messages');
const USER_INPUT = document.querySelector('#user_input');
const TYPING_INDICATOR = document.querySelector('#typing');
const RESET_BUTTON = document.querySelector('.reset-button');
const IMAGE_INPUT = document.querySelector('.attach-button');
const HIDDEN_IMAGE_INPUT = document.querySelector('#image_input');


// === Session-related functions ===
const initialize_session = async () => {
    try {
        let response = await fetch('/api/start_session', {
            method: 'POST', credentials: 'include'
        })
        if (!response.ok) {
            throw new Error(`Session initialization failed with the following error: ${response.statusText}`);
        }
        console.info('[INFO] Session successfully initialized!')   
        return await response;
    } catch(error) {
        console.error(`[ERROR] Session initialization failed: ${error}`)
        throw(error)    
    }
}


// === Chatting-related functions ===
async function send_message(message, image_url = undefined, img_mimetype = undefined) {
    if (!message || !message.trim() || typeof(message) !== 'string') {
        throw new Error("'message' must be a non-empty string.");
    }

    try {
        SEND_BUTTON.disabled = true;
        IMAGE_INPUT.disabled = true;
        SEND_BUTTON.style.cursor = 'not-allowed';
        let response = await fetch('/api/send_message/', {
            method: 'POST', credentials: 'include',
            headers: {'Content-Type': 'application/json'},
            body: JSON.stringify({message: message, img_base64: image_url, img_mimetype: img_mimetype}) 
        });
        
        if (response.status === 401) {
            try {
                await initialize_session();
                response = await fetch('/api/send_message/', {
                    method: 'POST', credentials: 'include',
                    headers: {'Content-Type': 'application/json'},  
                    body: JSON.stringify({message: message, image_url: image_url})
                })
            } catch(error) {
                throw new Error(`Failed to initialize new session and send message: ${error}`)
            }
        }

        if (!response.ok) throw new Error(`Failed to send message: "${response.statusText}"`)
        return await response.json()
    } catch (error) {
        console.error(`[ERROR] Something happened while sending a message to the server: "${error}"`)
        throw error; 
    } finally {
        SEND_BUTTON.disabled = false;
        HIDDEN_IMAGE_INPUT.value = '';
        IMAGE_INPUT.disabled = false;
        IMAGE_INPUT.classList.toggle('active', true)
        SEND_BUTTON.classList.toggle('active', false)
        IMAGE_INPUT.style.cursor = 'pointer';
        SEND_BUTTON.style.cursor = 'pointer';
    }
}

// Adds a mesage to the MESSAGES element
function add_message(text, sender, file) {
    const msg_div = document.createElement('div');
    msg_div.classList.add('message', sender);

    if (text) {
        let text_node = document.createElement('div');
        text_node.textContent = text;
        msg_div.appendChild(text_node);
    }

    if (file) {
        let image = document.createElement('img');
        image.src = URL.createObjectURL(file)
        image.onload = function() {URL.revokeObjectURL(image.src)}
        msg_div.appendChild(image);
    }
    MESSAGES.appendChild(msg_div);
    MESSAGES.scrollTop = MESSAGES.scrollHeight;
}

// Shows the typing indicator for the bot...
function show_typing() {
    TYPING_INDICATOR.style.display = 'block';
    MESSAGES.appendChild(TYPING_INDICATOR); // Move to end
    MESSAGES.scrollTop = MESSAGES.scrollHeight;
}

// Hides the typing indicator for the bot...
function hide_typing() {
    TYPING_INDICATOR.style.display = 'none';
}

// Attach the event listeners required for the application's chatting functionality
// to function as per intended...
const setup_chat_interface = () => {
    SEND_BUTTON.addEventListener('click', async function() {
        let message = USER_INPUT.value.trim();
        let file = HIDDEN_IMAGE_INPUT.files[0];
        let base64_string, img_mimetype;
        if ((!message || !message && !file) || SEND_BUTTON.disabled) return;

        // If the user's uploaded a file, then Base64-encode it before sending it over 
        // to the Sinatra app.
        if (file) {
            let file_data = await new Promise((resolve, reject) => {
                let reader = new FileReader();
                reader.onload = (e) => {
                    base64_string = e.target.result.split(',')[1];
                    img_mimetype = file.type
                    resolve({base64_string, img_mimetype})
                };
                reader.onerror = (e) => reject(new Error("Couldn't read the file for some reason."));
                reader.readAsDataURL(file);
            });
        }
            
        try {
            USER_INPUT.value = ''; USER_INPUT.disabled = true;
            IMAGE_INPUT.value = '';
            clear_image_preview();
            update_button_state();
            add_message(message, 'user', file); show_typing();
            let response = await send_message(message, base64_string, img_mimetype)
            hide_typing()
            add_message(response['returned_message'], 'bot');
        } catch(error) {
            console.error(`[ERROR] Something went wrong while sending a message to the server: ${error}`);
            hide_typing();
            alert('Your message failed to be processed by the server; please try sending your message again!');
        } finally {
            SEND_BUTTON.classList.toggle('active', false)
            USER_INPUT.disabled = false;
        }
    })

    USER_INPUT.addEventListener('keypress', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) {
            e.preventDefault();
            SEND_BUTTON.click();
        }
    })
}


// === Message sending button-related items ===
const update_button_state = () => {
    let has_text = USER_INPUT.value.trim().length > 0
    let has_image = HIDDEN_IMAGE_INPUT.files.length > 0;

    // Deal with the image input functionality here:
    IMAGE_INPUT.classList.toggle('active', !has_image);
    if (has_image) {
        let should_be_active = (has_text && has_image) 
        IMAGE_INPUT.disabled = true; IMAGE_INPUT.style.cursor = 'not-allowed';
        SEND_BUTTON.classList.toggle('active',  should_be_active)
        SEND_BUTTON.disabled = !should_be_active
    } else {
        SEND_BUTTON.classList.toggle('active',  has_text)
        SEND_BUTTON.disabled = !has_text
        IMAGE_INPUT.disabled = false; IMAGE_INPUT.style.cursor = 'pointer';
    }
}


// === For the resetting functionality on the upper right hand corner ===
let initialize_reset_button = () => {
    RESET_BUTTON.addEventListener('click', function() {
        let reset_conversation = confirm('Are you sure you want to reset the conversation?');
        if (reset_conversation) {
            MESSAGES.innerHTML = '';
            fetch('/api/restart_chat/', {method: 'POST'})
            .then(data => data.json())
            .then(response => {console.info(`[INFO] Status: ${response['message']}`)})
            .catch(error => {
                console.error(error['message']);
                alert('The application could not restart the chatting session; do refresh the application to see if anything changes!');
            })
            SEND_BUTTON.classList.toggle('active', false);
            IMAGE_INPUT.classList.toggle('active', true);
        } else {
            return;
        }
    })
}


// Initialize the session when the page loads:
document.addEventListener('DOMContentLoaded', async () => {
    try {
        await initialize_session();
        IMAGE_INPUT.classList.toggle('active', true);
        USER_INPUT.addEventListener('input', update_button_state);
        HIDDEN_IMAGE_INPUT.addEventListener('change', update_button_state);
        document.querySelector('.attach-button').addEventListener('click', () => {document.querySelector('#image_input').click()})
        initialize_reset_button()
        setup_chat_interface();
        add_message("Welcome!  Please enter a message to get started!", "bot")
    } catch(error) {
        console.error(`[ERROR] Failed to set up the initial session: ${error}`);
        alert("The application was unable to initialize itself; could you refresh the page after this message?");
    }
})