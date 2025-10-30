/*
 * A JavaScript file I made to deal with that paperclip icon - for handling file uploads.
 * I suspect that the JavaScript behind this can get a bit gnarly, so just in case - we'll store the code 
 * in a separate file for the sake of maintainability and modularizability.
 * 
 * -- Kevin
*/

// Some file-level constants...
let IMAGE_PREVIEW = document.querySelector('.image_preview');

// Clears out the image preview if the user clicks on the "X" button:
const clear_image_preview = () => {
    IMAGE_PREVIEW.innerHTML = '';
    IMAGE_PREVIEW.value = '';
    HIDDEN_IMAGE_INPUT.value = '';
    update_button_state();          // Taken from message_and_session.js
}

// Attach an event listener such that if the user uploads an image, they'll be able to preview it right next to the 
// attach button (i.e., the clippy icon):
HIDDEN_IMAGE_INPUT.addEventListener('change', function() {
    IMAGE_PREVIEW.innerHTML = '';
    let file = this.files[0]
    if (file) {
        let preview = document.createElement('img');
        preview.src = URL.createObjectURL(file);
        preview.style.maxWidth = '50px';
        preview.style.maxHeight = '50px';
        preview.style.borderRadius = '5px';
        preview.onload = function() {URL.revokeObjectURL(preview.src)};

        // Add the removal button here:
        let remove_button = document.createElement('button');
        remove_button.className = 'remove-button';
        remove_button.textContent = 'x';
        remove_button.addEventListener('click', clear_image_preview);

        // Finally, add the preview image and its associated "close" button 
        // to the image_preview <div> tag:
        IMAGE_PREVIEW.appendChild(preview);
        IMAGE_PREVIEW.appendChild(remove_button);
    }
})
