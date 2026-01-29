/**
 * Clipboard Service
 * Handles clipboard-related functionality for exam questions
 */

/**
 * Copy text to remote desktop clipboard via facilitator API
 * @param {string} content - Text content to copy
 * @private
 */
async function copyToRemoteClipboard(content) {
    try {
        // Fire and forget API call
        fetch('/facilitator/api/v1/remote-desktop/clipboard', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ content })
        });
    } catch (error) {
        console.error('Failed to copy to remote clipboard:', error);
        // Don't throw error as this is a non-critical operation
    }
}

/**
 * Show simple copy notification
 * @param {string} content - Content that was copied
 */
function showCopyNotification(content) {
    // Create a simple notification
    const notification = document.createElement('div');
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #28a745;
        color: white;
        padding: 10px 15px;
        border-radius: 5px;
        z-index: 9999;
        font-size: 14px;
        box-shadow: 0 2px 10px rgba(0,0,0,0.2);
    `;
    notification.textContent = `Copied: ${content.length > 30 ? content.substring(0, 30) + '...' : content}`;
    
    document.body.appendChild(notification);
    
    // Remove after 2 seconds
    setTimeout(() => {
        if (notification.parentNode) {
            notification.parentNode.removeChild(notification);
        }
    }, 2000);
}

/**
 * Setup click-to-copy functionality for all clickable elements
 */
function setupClickToCopy() {
    document.addEventListener('click', function(event) {
        let target = event.target;
        
        // Traverse up the DOM tree to find element with data-copy-text attribute
        // This handles cases where user clicks on text inside the element
        while (target && target !== document) {
            if (target.hasAttribute && target.hasAttribute('data-copy-text')) {
                const copyText = target.getAttribute('data-copy-text');
                
                // Copy to remote desktop clipboard
                copyToRemoteClipboard(copyText);
                
                // Copy to local clipboard
                navigator.clipboard.writeText(copyText).then(() => {
                    showCopyNotification(copyText);
                }).catch(err => {
                    console.error('Could not copy text to clipboard:', err);
                    // Fallback for older browsers
                    try {
                        const textArea = document.createElement('textarea');
                        textArea.value = copyText;
                        document.body.appendChild(textArea);
                        textArea.select();
                        document.execCommand('copy');
                        document.body.removeChild(textArea);
                        showCopyNotification(copyText);
                    } catch (fallbackErr) {
                        console.error('Fallback copy failed:', fallbackErr);
                    }
                });
                
                // Prevent default behavior
                event.preventDefault();
                event.stopPropagation();
                return;
            }
            target = target.parentElement;
        }
    });
}

/**
 * Setup click-to-copy functionality for inline code elements (legacy support)
 */
function setupInlineCodeCopy() {
    document.addEventListener('click', function(event) {
        if (event.target && event.target.matches('.inline-code')) {
            const codeText = event.target.textContent;

            // Copy to remote desktop clipboard
            copyToRemoteClipboard(codeText);
            
            // Copy to local clipboard
            navigator.clipboard.writeText(codeText).then(() => {
                showCopyNotification(codeText);
            }).catch(err => {
                console.error('Could not copy text to clipboard:', err);
            });
        }
    });
}

/**
 * Intercept copy events to ensure only clean text is copied (no HTML attributes)
 * This handles manual text selection (Ctrl+C or right-click copy)
 */
function setupCopyInterception() {
    document.addEventListener('copy', function(event) {
        const selection = window.getSelection();
        if (!selection || selection.rangeCount === 0) {
            return;
        }
        
        const range = selection.getRangeAt(0);
        const selectedText = selection.toString();
        
        // Check if selection contains HTML attributes (means HTML is being copied as text)
        if (selectedText.includes('title="Click to copy"') || 
            selectedText.includes('data-copy-text=') || 
            selectedText.includes('<span class=') ||
            selectedText.includes('<code class=')) {
            
            // Try to extract clean text from clickable-code elements in the selection
            const tempDiv = document.createElement('div');
            tempDiv.appendChild(range.cloneContents());
            const codeElements = tempDiv.querySelectorAll('.clickable-code[data-copy-text]');
            
            if (codeElements.length > 0) {
                const cleanTexts = Array.from(codeElements).map(el => {
                    const text = el.getAttribute('data-copy-text');
                    return text ? decodeHtmlEntities(text) : null;
                }).filter(Boolean);
                
                if (cleanTexts.length > 0) {
                    const combinedText = cleanTexts.join(' ');
                    event.clipboardData.setData('text/plain', combinedText);
                    event.preventDefault();
                    
                    copyToRemoteClipboard(combinedText);
                    showCopyNotification(cleanTexts.length === 1 ? cleanTexts[0] : combinedText);
                    return;
                }
            }
            
            // Fallback: aggressively clean HTML from the text
            let cleanedText = selectedText
                .replace(/title="Click to copy">?/g, '')
                .replace(/data-copy-text="[^"]*"/g, '')
                .replace(/<span[^>]*>/g, '')
                .replace(/<\/span>/g, '')
                .replace(/<code[^>]*>/g, '')
                .replace(/<\/code>/g, '')
                .replace(/<[^>]*>/g, '') // Remove any remaining HTML tags
                .replace(/&quot;/g, '"')
                .replace(/&amp;/g, '&')
                .replace(/&lt;/g, '<')
                .replace(/&gt;/g, '>')
                .replace(/&nbsp;/g, ' ')
                .replace(/\s+/g, ' ') // Normalize whitespace
                .trim();
            
            if (cleanedText !== selectedText && cleanedText.length > 0) {
                event.clipboardData.setData('text/plain', cleanedText);
                event.preventDefault();
                
                copyToRemoteClipboard(cleanedText);
                showCopyNotification(cleanedText.length > 50 ? cleanedText.substring(0, 50) + '...' : cleanedText);
                return;
            }
        }
        
        // Check if selection is within a clickable-code element
        let container = range.commonAncestorContainer;
        let element = container.nodeType === Node.TEXT_NODE ? container.parentElement : container;
        
        // Traverse up to find clickable-code element
        while (element && element !== document.body) {
            if (element.classList && element.classList.contains('clickable-code')) {
                const cleanText = element.getAttribute('data-copy-text');
                if (cleanText) {
                    const decodedText = decodeHtmlEntities(cleanText);
                    event.clipboardData.setData('text/plain', decodedText);
                    event.preventDefault();
                    
                    copyToRemoteClipboard(decodedText);
                    showCopyNotification(decodedText);
                    return;
                }
            }
            element = element.parentElement;
        }
    });
}

/**
 * Decode HTML entities in text
 */
function decodeHtmlEntities(text) {
    const textarea = document.createElement('textarea');
    textarea.innerHTML = text;
    return textarea.value;
}

export {
    setupClickToCopy,
    setupInlineCodeCopy,
    setupCopyInterception
}; 