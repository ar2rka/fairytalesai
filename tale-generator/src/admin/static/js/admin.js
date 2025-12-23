// Admin Panel JavaScript

// API Base URL
const API_BASE_URL = '/api/v1';

// DOM Elements
const storiesContainer = document.getElementById('stories-container');
const childFilter = document.getElementById('child-filter');
const languageFilter = document.getElementById('language-filter');
const modelFilter = document.getElementById('model-filter');
const ratingFilter = document.getElementById('rating-filter');
const sortBy = document.getElementById('sort-by');
const refreshBtn = document.getElementById('refresh-btn');
const totalStoriesEl = document.getElementById('total-stories');
const totalChildrenEl = document.getElementById('total-children');
const avgRatingEl = document.getElementById('avg-rating');
const storyModal = document.getElementById('story-modal');
const closeModal = document.querySelector('.close');
const storyDetailContent = document.getElementById('story-detail-content');

// Story Generation Form Elements
const storyGenerationForm = document.getElementById('story-generation-form');
const generationStatus = document.getElementById('generation-status');

// Generated Story Section Elements
const generatedStorySection = document.getElementById('generated-story-section');
const generatedStoryContent = document.getElementById('generated-story-content');
const closeStoryBtn = document.getElementById('close-story-btn');

// State
let allStories = [];
let allChildren = [];

// Initialize the admin panel
document.addEventListener('DOMContentLoaded', async function() {
    // Load data
    await loadData();
    
    // Set up event listeners
    setupEventListeners();
});

// Set up event listeners
function setupEventListeners() {
    childFilter.addEventListener('change', filterStories);
    languageFilter.addEventListener('change', filterStories);
    modelFilter.addEventListener('change', filterStories);
    ratingFilter.addEventListener('change', filterStories);
    sortBy.addEventListener('change', filterStories);
    refreshBtn.addEventListener('click', loadData);
    
    // Story generation form submission
    if (storyGenerationForm) {
        storyGenerationForm.addEventListener('submit', generateStory);
    }
    
    // Close generated story section
    if (closeStoryBtn) {
        closeStoryBtn.addEventListener('click', () => {
            generatedStorySection.classList.add('hidden');
        });
    }
    
    // Close modal when clicking on close button
    closeModal.addEventListener('click', () => {
        storyModal.style.display = 'none';
    });
    
    // Close modal when clicking outside of it
    window.addEventListener('click', (event) => {
        if (event.target === storyModal) {
            storyModal.style.display = 'none';
        }
    });
}

// Load all data
async function loadData() {
    try {
        // Show loading state
        storiesContainer.innerHTML = '<div class="empty-state"><div class="loading"></div><p>Loading stories...</p></div>';
        
        // Fetch stories and children in parallel
        const [storiesResponse, childrenResponse] = await Promise.all([
            fetch(`${API_BASE_URL}/stories`),
            fetch(`${API_BASE_URL}/children`)
        ]);
        
        if (!storiesResponse.ok || !childrenResponse.ok) {
            throw new Error('Failed to fetch data');
        }
        
        allStories = await storiesResponse.json();
        allChildren = await childrenResponse.json();
        
        // Update stats
        updateStats();
        
        // Populate filters
        populateFilters();
        
        // Display stories
        displayStories(allStories);
        
    } catch (error) {
        console.error('Error loading data:', error);
        storiesContainer.innerHTML = '<div class="empty-state"><i class="fas fa-exclamation-triangle fa-3x"></i><p>Error loading stories. Please try again.</p></div>';
    }
}

// Generate a new story
async function generateStory(event) {
    event.preventDefault();
    
    // Get form data
    const childName = document.getElementById('child-name').value;
    const childAge = parseInt(document.getElementById('child-age').value);
    const childGender = document.getElementById('child-gender').value;
    const childInterests = document.getElementById('child-interests').value.split(',').map(item => item.trim()).filter(item => item);
    const storyMoral = document.getElementById('story-moral').value;
    const customMoral = document.getElementById('custom-moral').value;
    const storyLanguage = document.getElementById('story-language').value;
    
    // Validate required fields
    if (!childName || !childAge || !childGender) {
        alert('Please fill in all required fields');
        return;
    }
    
    // Show loading status
    generationStatus.classList.remove('hidden');
    
    try {
        // Prepare the request payload
        const payload = {
            child: {
                name: childName,
                age: childAge,
                gender: childGender,
                interests: childInterests
            },
            language: storyLanguage
        };
        
        // Add moral if specified
        if (customMoral) {
            payload.custom_moral = customMoral;
        } else if (storyMoral) {
            payload.moral = storyMoral;
        }
        
        // Send request to generate story
        const response = await fetch(`${API_BASE_URL}/generate-story`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });
        
        if (!response.ok) {
            throw new Error(`Failed to generate story: ${response.status} ${response.statusText}`);
        }
        
        const result = await response.json();
        
        // Hide loading status
        generationStatus.classList.add('hidden');
        
        // Display the generated story directly on the page
        displayGeneratedStory(result);
        
        // Show success message
        alert(`Story "${result.title}" generated successfully!`);
        
        // Reset form
        storyGenerationForm.reset();
        
        // Reload data to show the new story in the list
        await loadData();
        
    } catch (error) {
        console.error('Error generating story:', error);
        generationStatus.classList.add('hidden');
        alert(`Error generating story: ${error.message}`);
    }
}

// Update statistics
function updateStats() {
    totalStoriesEl.textContent = allStories.length;
    totalChildrenEl.textContent = allChildren.length;
    
    // Calculate average rating
    const ratedStories = allStories.filter(story => story.rating !== null);
    if (ratedStories.length > 0) {
        const sum = ratedStories.reduce((acc, story) => acc + story.rating, 0);
        const avg = sum / ratedStories.length;
        avgRatingEl.textContent = avg.toFixed(1);
    } else {
        avgRatingEl.textContent = '-';
    }
}

// Populate filter dropdowns
function populateFilters() {
    // Clear existing options
    childFilter.innerHTML = '<option value="">All Children</option>';
    modelFilter.innerHTML = '<option value="">All Models</option>';
    
    // Get unique child names
    const childNames = [...new Set(allStories.map(story => story.child_name).filter(name => name))];
    
    // Get unique model names
    const modelNames = [...new Set(allStories.map(story => story.model_used).filter(model => model))];
    
    // Add options for each child
    childNames.forEach(name => {
        const option = document.createElement('option');
        option.value = name;
        option.textContent = name;
        childFilter.appendChild(option);
    });
    
    // Add options for each model
    modelNames.forEach(model => {
        const option = document.createElement('option');
        option.value = model;
        option.textContent = model;
        modelFilter.appendChild(option);
    });
}

// Filter and sort stories
function filterStories() {
    let filteredStories = [...allStories];
    
    // Apply child filter
    const selectedChild = childFilter.value;
    if (selectedChild) {
        filteredStories = filteredStories.filter(story => story.child_name === selectedChild);
    }
    
    // Apply language filter
    const selectedLanguage = languageFilter.value;
    if (selectedLanguage) {
        filteredStories = filteredStories.filter(story => story.language === selectedLanguage);
    }
    
    // Apply model filter
    const selectedModel = modelFilter.value;
    if (selectedModel) {
        filteredStories = filteredStories.filter(story => story.model_used === selectedModel);
    }
    
    // Apply rating filter
    const selectedRating = ratingFilter.value;
    if (selectedRating === 'rated') {
        filteredStories = filteredStories.filter(story => story.rating !== null);
    } else if (selectedRating === 'unrated') {
        filteredStories = filteredStories.filter(story => story.rating === null);
    }
    
    // Apply sorting
    const sortValue = sortBy.value;
    switch (sortValue) {
        case 'created_at_desc':
            filteredStories.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
            break;
        case 'created_at_asc':
            filteredStories.sort((a, b) => new Date(a.created_at) - new Date(b.created_at));
            break;
        case 'title_asc':
            filteredStories.sort((a, b) => a.title.localeCompare(b.title));
            break;
        case 'title_desc':
            filteredStories.sort((a, b) => b.title.localeCompare(a.title));
            break;
    }
    
    displayStories(filteredStories);
}

// Display stories in the grid
function displayStories(stories) {
    if (stories.length === 0) {
        storiesContainer.innerHTML = '<div class="empty-state"><i class="fas fa-book-open fa-3x"></i><p>No stories found matching your criteria.</p></div>';
        return;
    }
    
    storiesContainer.innerHTML = '';
    
    stories.forEach(story => {
        const storyCard = createStoryCard(story);
        storiesContainer.appendChild(storyCard);
    });
}

// Create a story card element
function createStoryCard(story) {
    const card = document.createElement('div');
    card.className = 'story-card';
    card.dataset.storyId = story.id;
    
    // Get excerpt (first 100 characters)
    const excerpt = story.content.length > 100 ? story.content.substring(0, 100) + '...' : story.content;
    
    // Format created date
    const createdDate = new Date(story.created_at);
    const formattedDate = createdDate.toLocaleDateString();
    
    card.innerHTML = `
        <div class="story-header">
            <h3 class="story-title">${escapeHtml(story.title)}</h3>
            <div class="story-meta">
                <span>${escapeHtml(story.child_name || 'Unknown')}</span>
                <span>${formattedDate}</span>
            </div>
        </div>
        <div class="story-content">
            <p class="story-excerpt">${escapeHtml(excerpt)}</p>
            <div class="story-tags">
                <span class="tag">${getLanguageName(story.language)}</span>
                <span class="tag">${escapeHtml(story.moral)}</span>
                ${story.model_used ? `<span class="tag">${escapeHtml(story.model_used)}</span>` : ''}
            </div>
        </div>
        <div class="story-footer">
            <div class="rating">
                ${story.rating ? 
                    `<span class="rating-value">${story.rating}/10</span>` : 
                    `<span class="rating-value">Not rated</span>`
                }
            </div>
            <button class="btn-primary" onclick="viewStoryDetail('${story.id}')">
                View Details
            </button>
        </div>
    `;
    
    // Add click event to open detail view
    card.addEventListener('click', (e) => {
        if (!e.target.closest('button')) {
            viewStoryDetail(story.id);
        }
    });
    
    return card;
}

// View story detail
async function viewStoryDetail(storyId) {
    try {
        // Show loading in modal
        storyDetailContent.innerHTML = '<div class="loading"></div><p>Loading story details...</p>';
        storyModal.style.display = 'block';
        
        // Fetch story details
        const response = await fetch(`${API_BASE_URL}/stories/${storyId}`);
        if (!response.ok) {
            throw new Error('Failed to fetch story details');
        }
        
        const story = await response.json();
        
        // Format created and updated dates
        const createdDate = new Date(story.created_at);
        const updatedDate = new Date(story.updated_at);
        const formattedCreated = createdDate.toLocaleString();
        const formattedUpdated = updatedDate.toLocaleString();
        
        // Render story detail
        storyDetailContent.innerHTML = `
            <div class="story-detail">
                <div class="story-detail-header">
                    <h1 class="story-detail-title">${escapeHtml(story.title)}</h1>
                    <div class="story-detail-meta">
                        <span><i class="fas fa-user"></i> ${escapeHtml(story.child_name || 'Unknown')}</span>
                        <span><i class="fas fa-language"></i> ${getLanguageName(story.language)}</span>
                        <span><i class="fas fa-heart"></i> ${escapeHtml(story.moral)}</span>
                        ${story.rating ? `<span><i class="fas fa-star"></i> ${story.rating}/10</span>` : ''}
                    </div>
                </div>
                
                <div class="story-detail-content">
                    ${escapeHtml(story.content).replace(/\n/g, '<br>')}
                </div>
                
                <div class="story-detail-footer">
                    <div>
                        <p><strong>Model:</strong> ${escapeHtml(story.model_used || 'Unknown')}</p>
                        <p><strong>Created:</strong> ${formattedCreated}</p>
                        <p><strong>Updated:</strong> ${formattedUpdated}</p>
                    </div>
                </div>
            </div>
        `;
        
    } catch (error) {
        console.error('Error loading story detail:', error);
        storyDetailContent.innerHTML = '<div class="empty-state"><i class="fas fa-exclamation-triangle fa-3x"></i><p>Error loading story details. Please try again.</p></div>';
    }
}

// Helper function to escape HTML
function escapeHtml(text) {
    const map = {
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#039;'
    };
    
    return text.toString().replace(/[&<>"']/g, function(m) { return map[m]; });
}

// Generate a new story
async function generateStory(event) {
    event.preventDefault();
    
    // Get form data
    const childName = document.getElementById('child-name').value;
    const childAge = parseInt(document.getElementById('child-age').value);
    const childGender = document.getElementById('child-gender').value;
    const childInterests = document.getElementById('child-interests').value.split(',').map(item => item.trim()).filter(item => item);
    const storyMoral = document.getElementById('story-moral').value;
    const customMoral = document.getElementById('custom-moral').value;
    const storyLanguage = document.getElementById('story-language').value;
    
    // Validate required fields
    if (!childName || !childAge || !childGender) {
        alert('Please fill in all required fields');
        return;
    }
    
    // Show loading status
    generationStatus.classList.remove('hidden');
    
    try {
        // Prepare the request payload
        const payload = {
            child: {
                name: childName,
                age: childAge,
                gender: childGender,
                interests: childInterests
            },
            language: storyLanguage
        };
        
        // Add moral if specified
        if (customMoral) {
            payload.custom_moral = customMoral;
        } else if (storyMoral) {
            payload.moral = storyMoral;
        }
        
        // Send request to generate story
        const response = await fetch(`${API_BASE_URL}/generate-story`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(payload)
        });
        
        if (!response.ok) {
            throw new Error(`Failed to generate story: ${response.status} ${response.statusText}`);
        }
        
        const result = await response.json();
        
        // Hide loading status
        generationStatus.classList.add('hidden');
        
        // Display the generated story directly on the page
        displayGeneratedStory(result);
        
        // Show success message
        alert(`Story "${result.title}" generated successfully!`);
        
        // Reset form
        storyGenerationForm.reset();
        
        // Reload data to show the new story in the list
        await loadData();
        
    } catch (error) {
        console.error('Error generating story:', error);
        generationStatus.classList.add('hidden');
        alert(`Error generating story: ${error.message}`);
    }
}

// Display the generated story directly on the page
function displayGeneratedStory(story) {
    // Populate the story content
    generatedStoryContent.innerHTML = `
        <h3>${escapeHtml(story.title)}</h3>
        <div class="story-text">${escapeHtml(story.content).replace(/\n/g, '<br>')}</div>
        <div class="story-details">
            <p><strong>Moral:</strong> ${escapeHtml(story.moral)}</p>
            <p><strong>Language:</strong> ${getLanguageName(story.language)}</p>
            ${story.story_length ? `<p><strong>Length:</strong> ${story.story_length} minutes</p>` : ''}
        </div>
    `;
    
    // Show the generated story section
    generatedStorySection.classList.remove('hidden');
    
    // Scroll to the generated story section
    generatedStorySection.scrollIntoView({ behavior: 'smooth' });
}

// Helper function to get language name
function getLanguageName(code) {
    const languages = {
        'en': 'English',
        'ru': 'Russian'
    };
    return languages[code] || code;
}