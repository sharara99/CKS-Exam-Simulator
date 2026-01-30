/**
 * Question Service
 * Handles question display and navigation
 */

// Process question content to improve formatting and highlighting
function processQuestionContent(content) {
    // First, preserve existing HTML formatting
    let processedContent = content;
    
    // Static variable for Calico URL - must be handled as complete unit
    const CALICO_URL = 'https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/tigera-operator.yaml';
    const CALICO_PLACEHOLDER = '__CALICO_URL_PLACEHOLDER__';
    
    // Replace Calico URL with placeholder first (before any regex processing)
    processedContent = processedContent.replace(new RegExp(CALICO_URL.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g'), CALICO_PLACEHOLDER);
    
    // Add click-to-copy functionality for URLs - PROCESS FIRST, BEFORE ANY OTHER TRANSFORMATIONS
    // This function matches complete URLs and makes them clickable/copyable
    // Examples:
    // - http://example.org/echo (working example)
    // - https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.9/cri-dockerd_0.3.9.3-0.ubuntu-jammy_amd64.deb
    // - https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/tigera-operator.yaml
    // - https://argoproj.github.io/argo-helm
    
    // Match complete URLs - match everything from https:// or http:// until whitespace or newline
    // Use a pattern that matches all valid URL characters (letters, numbers, dots, slashes, hyphens, etc.)
    // Stop only at whitespace, newlines, or HTML tags
    processedContent = processedContent.replace(
        /(https?:\/\/[a-zA-Z0-9\-._~:/?#[\]@!$&'()*+,;=%]+)/g,
        function(match) {
            // Skip if already inside an HTML tag
            if (match.includes('<') || match.includes('>')) {
                return match;
            }
            
            // Use the match as-is (it's the full URL)
            const fullUrl = match;
            
            // Escape HTML special characters for the data attribute
            const escapedUrl = fullUrl
                .replace(/&/g, '&amp;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;');
            
            // Return the clickable span with the full URL - same format as working example
            return '<span class="clickable-filepath" data-copy-text="' + escapedUrl + '" title="Click to copy URL">' + fullUrl + '</span>';
        }
    );
    
    // Add click-to-copy functionality for sysctl parameters (net.*=value format)
    // Match: net.ipv6.conf.all.forwarding=1, net.ipv4.ip_forward=1, etc.
    processedContent = processedContent.replace(
        /(net\.[a-zA-Z0-9._-]+=[0-9]+)/g,
        '<span class="clickable-filepath" data-copy-text="$1" title="Click to copy sysctl parameter">$1</span>'
    );
    
    // Process backticks - ONLY make things in backticks copyable
    // This is the primary way to mark copyable content (commands, paths, flags, values)
    // Process backticks BEFORE other text processing to avoid conflicts
    processedContent = processedContent.replace(
        /`([^`]+)`/g, 
        function(match, text) {
            // Skip if already inside an HTML tag (check if match contains HTML)
            if (match.includes('<') || match.includes('>') || match.includes('class=') || match.includes('data-copy-text')) {
                return match;
            }
            
            // Trim whitespace from the text
            const cleanText = text.trim();
            
            // Escape HTML special characters for the data attribute (for safe HTML attribute)
            // This is what gets copied to clipboard
            const escapedText = cleanText
                .replace(/&/g, '&amp;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;');
            
            // Display text - escape HTML to prevent XSS but allow normal rendering
            const displayText = cleanText
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;');
            
            // Return the HTML directly - ensure it's properly formed
            return '<code class="bg-light px-1 rounded clickable-code" data-copy-text="' + escapedText + '" title="Click to copy">' + displayText + '</code>';
        }
    );
    
    // Style bold text
    processedContent = processedContent.replace(
        /\*\*([^*]+)\*\*/g, 
        '<strong>$1</strong>'
    );
    
    // Style italic text
    processedContent = processedContent.replace(
        /\*([^*]+)\*/g, 
        '<em>$1</em>'
    );
    
    // Convert literal newline characters to HTML line breaks
    processedContent = processedContent.replace(/\n/g, '<br>');
    
    // Ensure paragraphs have proper spacing and line breaks
    processedContent = processedContent.replace(
        /<\/p><p>/g, 
        '</p>\n<p>'
    );
    
    // Add more spacing between list items
    processedContent = processedContent.replace(
        /<\/li><li>/g, 
        '</li>\n<li>'
    );
    
    // Restore Calico URL as clickable span (after all regex processing is complete)
    const calicoEscapedUrl = CALICO_URL
        .replace(/&/g, '&amp;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#39;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
    const calicoClickableSpan = '<span class="clickable-filepath" data-copy-text="' + calicoEscapedUrl + '" title="Click to copy URL">' + CALICO_URL + '</span>';
    processedContent = processedContent.replace(CALICO_PLACEHOLDER, calicoClickableSpan);
    
    return processedContent;
}

// Generate question content HTML
function generateQuestionContent(question) {
    try {
        // Get original data
        const originalData = question.originalData || {};
        const machineHostname = originalData.machineHostname || 'N/A';
        const namespace = originalData.namespace || 'N/A';
        const concepts = originalData.concepts || [];
        const conceptsString = concepts.join(', ');
        const documentation = originalData.documentation || [];
        
        // Format question content with improved styling
        const formattedQuestionContent = processQuestionContent(question.content);
        
        // Function to generate short label from URL
        function getDocLabel(url) {
            const urlLower = url.toLowerCase();
            // Map common patterns to short labels
            if (urlLower.includes('kubelet-config')) return 'kubelet-config';
            if (urlLower.includes('kubelet') && urlLower.includes('command-line')) return 'kubelet-cli';
            if (urlLower.includes('kubelet') && urlLower.includes('config-file')) return 'kubelet-file';
            if (urlLower.includes('kube-apiserver')) return 'kube-api';
            if (urlLower.includes('apiserver') && urlLower.includes('authorization')) return 'api-auth';
            if (urlLower.includes('noderestriction')) return 'node-restriction';
            if (urlLower.includes('imagepolicywebhook')) return 'image-webhook';
            if (urlLower.includes('admission-controllers')) return 'admission';
            if (urlLower.includes('admissionconfiguration')) return 'admission-config';
            if (urlLower.includes('security-context')) return 'security-context';
            if (urlLower.includes('pod-security-standards')) return 'pod-security';
            if (urlLower.includes('pod-security-admission')) return 'psa';
            if (urlLower.includes('network-policies')) return 'network-policy';
            if (urlLower.includes('network-policy')) return 'netpol';
            if (urlLower.includes('kubeadm') && urlLower.includes('upgrade')) return 'kubeadm-upgrade';
            if (urlLower.includes('drain')) return 'drain-node';
            if (urlLower.includes('service-account')) return 'serviceaccount';
            if (urlLower.includes('serviceaccount')) return 'sa';
            if (urlLower.includes('projected')) return 'projected-vol';
            if (urlLower.includes('secret')) return 'secrets';
            if (urlLower.includes('volume')) return 'volumes';
            if (urlLower.includes('runtime-class')) return 'runtime';
            if (urlLower.includes('container-runtimes')) return 'runtimes';
            if (urlLower.includes('audit')) return 'audit';
            if (urlLower.includes('etcd')) return 'etcd';
            if (urlLower.includes('rbac')) return 'rbac';
            if (urlLower.includes('deployment')) return 'deployment';
            // Fallback: extract meaningful part from URL
            const parts = url.split('/').filter(p => p && p !== 'docs' && p !== 'reference' && p !== 'tasks' && p !== 'concepts');
            const lastPart = parts[parts.length - 1] || '';
            return lastPart.replace(/\.html$/, '').replace(/-/g, '-').substring(0, 20);
        }
        
        // Generate documentation links HTML
        let documentationHtml = '';
        if (documentation && documentation.length > 0) {
            const docLinks = documentation.map(doc => {
                const label = getDocLabel(doc);
                return `<a href="${doc}" target="_blank" rel="noopener noreferrer" class="text-decoration-none me-2 mb-1 d-inline-block">
                    <span class="badge bg-info">${label}</span>
                </a>`;
            }).join('');
            documentationHtml = `
                <div class="mb-3">
                    <strong>Kubernetes Documentation:</strong>
                    <div class="mt-2">${docLinks}</div>
                </div>
            `;
        }
        
        // Create formatted content with minimal layout
        return `
            <div class="d-flex flex-column" style="height: 100%;">
                <div class="question-header">
                    
                    <div class="mb-3">
                        <strong>Solve this question on instance:</strong> <code class="bg-light px-1 rounded clickable-code" data-copy-text="ssh ${machineHostname}" title="Click to copy">ssh ${machineHostname}</code>
                    </div>
                    
                    <div class="mb-3">
                        <strong>Namespace:</strong> <span class="text-primary">${namespace}</span>
                    </div>
                    
                    <div class="mb-3">
                        <strong>Concepts:</strong> <span class="text-primary">${conceptsString}</span>
                    </div>
                    
                    ${documentationHtml}
                    
                    <hr class="my-3">
                </div>
                
                <div class="question-body">
                    ${formattedQuestionContent}
                </div>
                
                <div class="action-buttons-container mt-auto">
                    <div class="d-flex justify-content-between py-2">
                        <button class="btn ${question.flagged ? 'btn-warning' : 'btn-outline-warning'}" id="flagQuestionBtn">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-flag${question.flagged ? '-fill' : ''} me-2" viewBox="0 0 16 16">
                                <path d="M14.778.085A.5.5 0 0 1 15 .5V8a.5.5 0 0 1-.314.464L14.5 8l.186.464-.003.001-.006.003-.023.009a12.435 12.435 0 0 1-.397.15c-.264.095-.631.223-1.047.35-.816.252-1.879.523-2.71.523-.847 0-1.548-.28-2.158-.525l-.028-.01C7.68 8.71 7.14 8.5 6.5 8.5c-.7 0-1.638.23-2.437.477A19.626 19.626 0 0 0 3 9.342V15.5a.5.5 0 0 1-1 0V.5a.5.5 0 0 1 1 0v.282c.226-.079.496-.17.79-.26C4.606.272 5.67 0 6.5 0c.84 0 1.524.277 2.121.519l.043.018C9.286.788 9.828 1 10.5 1c.7 0 1.638-.23 2.437-.477a19.587 19.587 0 0 0 1.349-.476l.019-.007.004-.002h.001"/>
                            </svg>
                            ${question.flagged ? 'Flagged' : 'Flag for review'}
                        </button>
                        <button class="btn btn-success" id="nextQuestionBtn">
                            Satisfied with answer
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" fill="currentColor" class="bi bi-arrow-right ms-2" viewBox="0 0 16 16">
                                <path fill-rule="evenodd" d="M1 8a.5.5 0 0 1 .5-.5h11.793l-3.147-3.146a.5.5 0 0 1 .708-.708l4 4a.5.5 0 0 1 0 .708l-4 4a.5.5 0 0 1-.708-.708L13.293 8.5H1.5A.5.5 0 0 1 1 8z"/>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        `;
    } catch (error) {
        console.error('Error generating question content:', error);
        return '<div class="alert alert-danger">Error displaying question content. Please try refreshing the page.</div>';
    }
}

// Transform API response to question objects
function transformQuestionsFromApi(data) {
    if (data.questions && Array.isArray(data.questions)) {
        // Transform the questions to match our expected format
        return data.questions.map(q => ({
            id: q.id,
            content: q.question || '', // Map 'question' field to 'content'
            title: `Question ${q.id}`,  // Create a title from the ID
            originalData: q, // Keep original data for reference if needed
            flagged: false // Add flagged status property
        }));
    }
    return [];
}

// Update question dropdown
function updateQuestionDropdown(questionsArray, dropdownMenu, currentId, onQuestionSelect) {
    // Clear existing dropdown items
    dropdownMenu.innerHTML = '';
    
    // Add items for each question
    questionsArray.forEach((question) => {
        const li = document.createElement('li');
        const a = document.createElement('a');
        a.className = 'dropdown-item';
        a.href = '#';
        a.dataset.question = question.id;
        a.textContent = `Question ${question.id}`;
        
        // Add flag icon if question is flagged
        if (question.flagged) {
            const flagIcon = document.createElement('span');
            flagIcon.className = 'flag-icon ms-2';
            flagIcon.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="currentColor" class="bi bi-flag-fill text-warning" viewBox="0 0 16 16"><path d="M14.778.085A.5.5 0 0 1 15 .5V8a.5.5 0 0 1-.314.464L14.5 8l.186.464-.003.001-.006.003-.023.009a12.435 12.435 0 0 1-.397.15c-.264.095-.631.223-1.047.35-.816.252-1.879.523-2.71.523-.847 0-1.548-.28-2.158-.525l-.028-.01C7.68 8.71 7.14 8.5 6.5 8.5c-.7 0-1.638.23-2.437.477A19.626 19.626 0 0 0 3 9.342V15.5a.5.5 0 0 1-1 0V.5a.5.5 0 0 1 1 0v.282c.226-.079.496-.17.79-.26C4.606.272 5.67 0 6.5 0c.84 0 1.524.277 2.121.519l.043.018C9.286.788 9.828 1 10.5 1c.7 0 1.638-.23 2.437-.477a19.587 19.587 0 0 0 1.349-.476l.019-.007.004-.002h.001"/></svg>';
            a.appendChild(flagIcon);
        }
        
        // Add click event
        a.addEventListener('click', function(e) {
            e.preventDefault();
            const clickedQuestionId = this.dataset.question;
            if (onQuestionSelect) {
                onQuestionSelect(clickedQuestionId);
            }
        });
        
        li.appendChild(a);
        dropdownMenu.appendChild(li);
    });
}

export {
    processQuestionContent,
    generateQuestionContent,
    transformQuestionsFromApi,
    updateQuestionDropdown
}; 