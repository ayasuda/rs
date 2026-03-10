// Recipe ingredients data - will be loaded from API
let INGREDIENTS = {
    noodles: [],
    soup: [],
    sauce: [],
    oil: [],
    topping: [],
    presentation: []
};

// Game configuration
const config = {
    type: Phaser.AUTO,
    width: 1200,
    height: 800,
    parent: 'game-container',
    backgroundColor: '#34495e',
    scene: {
        preload: preload,
        create: create
    }
};

// Current recipe state
let currentRecipe = {
    noodles: null,
    soup: null,
    sauce: null,
    oil: null,
    toppings: [],
    presentation: null,
    cookingSkillLevel: 5.0
};

// UI elements
let scene;
let recipeDisplays = {};
let evaluationResults = null;
let dropdowns = {};
let loadingText = null;

function preload() {
    // No assets to preload for this minimal prototype
}

// Load ingredients from backend API
async function loadIngredientsFromAPI() {
    const response = await fetch('http://localhost:8080/master/ingredients');
    if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
    }
    
    const ingredients = await response.json();
    
    // Group ingredients by category
    INGREDIENTS = {
        noodles: [],
        soup: [],
        sauce: [],
        oil: [],
        topping: [],
        presentation: []
    };
    
    ingredients.forEach(ingredient => {
        if (INGREDIENTS[ingredient.category]) {
            INGREDIENTS[ingredient.category].push(ingredient);
        }
    });
    
    console.log('Loaded ingredients:', INGREDIENTS);
}

async function create() {
    scene = this;
    
    // Title
    this.add.text(600, 50, 'Ramen Recipe Creator', {
        fontSize: '32px',
        fill: '#ecf0f1',
        fontWeight: 'bold'
    }).setOrigin(0.5);

    // Loading message
    loadingText = this.add.text(600, 400, 'Loading ingredients from server...', {
        fontSize: '18px',
        fill: '#f39c12'
    }).setOrigin(0.5);

    try {
        // Fetch ingredients from backend
        await loadIngredientsFromAPI();
        
        // Clear loading message
        loadingText.destroy();
        
        // Instructions
        this.add.text(600, 90, 'Select ingredients for your ramen recipe:', {
            fontSize: '18px',
            fill: '#bdc3c7'
        }).setOrigin(0.5);

        // Create ingredient selection sections with dropdowns
        createDropdownSection('noodles', '麺', 50, 150);
        createDropdownSection('soup', 'スープ', 50, 200);
        createDropdownSection('sauce', 'かえし', 50, 250);
        createDropdownSection('oil', '香味油', 50, 300);
        createDropdownSection('topping', '具材', 50, 350);
        createDropdownSection('presentation', '盛り付け', 50, 400);

        // Cooking skill level
        createSkillLevelSection(50, 470);

        // Confirm button
        const confirmButton = scene.add.text(300, 550, 'Confirm Recipe', {
            fontSize: '20px',
            fill: '#2ecc71',
            backgroundColor: '#27ae60',
            padding: { x: 15, y: 8 }
        }).setOrigin(0.5).setInteractive();

        confirmButton.on('pointerdown', evaluateRecipe);
        confirmButton.on('pointerover', () => confirmButton.setTint(0xcccccc));
        confirmButton.on('pointerout', () => confirmButton.clearTint());

        // Results area
        scene.add.text(650, 150, 'Evaluation Results:', {
            fontSize: '18px',
            fill: '#ecf0f1',
            fontWeight: 'bold'
        });

    } catch (error) {
        console.error('Failed to load ingredients:', error);
        loadingText.setText('Error: Could not load ingredients from server.\nMake sure the Go server is running on localhost:8080');
        loadingText.setFill('#e74c3c');
    }
}

function createDropdownSection(category, label, x, y) {
    // Section label
    scene.add.text(x, y, label + ':', {
        fontSize: '16px',
        fill: '#ecf0f1',
        fontWeight: 'bold'
    });

    // Current selection display
    recipeDisplays[category] = scene.add.text(x + 120, y, 'None selected', {
        fontSize: '14px',
        fill: '#f39c12'
    });

    // Dropdown button
    const dropdownButton = scene.add.text(x + 350, y, '▼ Select', {
        fontSize: '14px',
        fill: '#3498db',
        backgroundColor: '#2980b9',
        padding: { x: 10, y: 5 }
    }).setInteractive();

    dropdowns[category] = {
        button: dropdownButton,
        isOpen: false,
        options: [],
        selectedOption: null
    };

    dropdownButton.on('pointerdown', () => toggleDropdown(category));
    dropdownButton.on('pointerover', () => dropdownButton.setTint(0xcccccc));
    dropdownButton.on('pointerout', () => dropdownButton.clearTint());
}

function createSkillLevelSection(x, y) {
    scene.add.text(x, y, 'Cooking Skill Level:', {
        fontSize: '16px',
        fill: '#ecf0f1',
        fontWeight: 'bold'
    });

    recipeDisplays.skillLevel = scene.add.text(x + 180, y, '5.0', {
        fontSize: '14px',
        fill: '#f39c12'
    });

    // Skill level buttons
    for (let i = 1; i <= 10; i++) {
        const button = scene.add.text(x + 350 + ((i-1) * 40), y, i.toString(), {
            fontSize: '12px',
            fill: '#9b59b6',
            backgroundColor: '#8e44ad',
            padding: { x: 6, y: 4 }
        }).setInteractive();

        button.on('pointerdown', () => {
            currentRecipe.cookingSkillLevel = i;
            recipeDisplays.skillLevel.setText(i.toString());
        });
        button.on('pointerover', () => button.setTint(0xcccccc));
        button.on('pointerout', () => button.clearTint());
    }
}

function toggleDropdown(category) {
    const dropdown = dropdowns[category];
    
    // Close all other dropdowns first
    Object.keys(dropdowns).forEach(cat => {
        if (cat !== category && dropdowns[cat].isOpen) {
            closeDropdown(cat);
        }
    });
    
    if (dropdown.isOpen) {
        closeDropdown(category);
    } else {
        openDropdown(category);
    }
}

function openDropdown(category) {
    const dropdown = dropdowns[category];
    const ingredients = INGREDIENTS[category];
    
    if (!ingredients || ingredients.length === 0) return;
    
    dropdown.isOpen = true;
    dropdown.button.setText('▲ Select');
    
    // Create dropdown options
    ingredients.forEach((ingredient, index) => {
        const optionY = dropdown.button.y + 30 + (index * 25);
        const optionText = scene.add.text(dropdown.button.x, optionY, ingredient.name, {
            fontSize: '12px',
            fill: '#ecf0f1',
            backgroundColor: '#34495e',
            padding: { x: 8, y: 3 }
        }).setInteractive();
        
        optionText.on('pointerdown', () => selectIngredient(category, ingredient));
        optionText.on('pointerover', () => optionText.setTint(0xcccccc));
        optionText.on('pointerout', () => optionText.clearTint());
        
        dropdown.options.push(optionText);
    });
}

function closeDropdown(category) {
    const dropdown = dropdowns[category];
    
    dropdown.isOpen = false;
    dropdown.button.setText('▼ Select');
    
    // Remove all option texts
    dropdown.options.forEach(option => option.destroy());
    dropdown.options = [];
}

function selectIngredient(category, ingredient) {
    // Close the dropdown after selection
    closeDropdown(category);
    
    if (category === 'topping') {
        // Handle multiple toppings selection
        const index = currentRecipe.toppings.findIndex(t => t.id === ingredient.id);
        if (index === -1) {
            if (currentRecipe.toppings.length < 3) { // Limit to 3 toppings
                currentRecipe.toppings.push(ingredient);
            } else {
                alert('Maximum 3 toppings allowed');
                return;
            }
        } else {
            currentRecipe.toppings.splice(index, 1);
        }
        
        const toppingsText = currentRecipe.toppings.length > 0 
            ? currentRecipe.toppings.map(t => t.name).join(', ')
            : 'None selected';
        recipeDisplays.topping.setText(toppingsText);
    } else {
        // Single selection for other categories
        currentRecipe[category] = ingredient;
        recipeDisplays[category].setText(ingredient.name);
    }
}

async function evaluateRecipe() {
    // Validate recipe completeness
    if (!currentRecipe.noodles || !currentRecipe.soup || !currentRecipe.sauce || 
        !currentRecipe.oil || !currentRecipe.presentation) {
        alert('Please select all required ingredients!');
        return;
    }

    // Close any open dropdowns
    Object.keys(dropdowns).forEach(category => {
        if (dropdowns[category].isOpen) {
            closeDropdown(category);
        }
    });

    // Prepare request body with proper category names
    const requestBody = {
        noodles: {
            id: currentRecipe.noodles.id,
            name: currentRecipe.noodles.name,
            category: 'noodles'
        },
        soup: {
            id: currentRecipe.soup.id,
            name: currentRecipe.soup.name,
            category: 'soup'
        },
        sauce: {
            id: currentRecipe.sauce.id,
            name: currentRecipe.sauce.name,
            category: 'sauce'
        },
        oil: {
            id: currentRecipe.oil.id,
            name: currentRecipe.oil.name,
            category: 'oil'
        },
        toppings: currentRecipe.toppings.map(topping => ({
            id: topping.id,
            name: topping.name,
            category: 'topping'
        })),
        presentation: {
            id: currentRecipe.presentation.id,
            name: currentRecipe.presentation.name,
            category: 'presentation'
        },
        cookingSkillLevel: currentRecipe.cookingSkillLevel
    };

    try {
        // Show loading message
        if (evaluationResults) {
            evaluationResults.destroy();
        }
        evaluationResults = scene.add.text(650, 180, 'Evaluating recipe...', {
            fontSize: '14px',
            fill: '#f39c12'
        });

        // Send request to backend
        const response = await fetch('http://localhost:8080/recipes/evaluate', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(requestBody)
        });

        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }

        const result = await response.json();
        displayEvaluationResults(result);

    } catch (error) {
        console.error('Error evaluating recipe:', error);
        if (evaluationResults) {
            evaluationResults.destroy();
        }
        evaluationResults = scene.add.text(650, 180, 'Error: Could not connect to server.\nMake sure the Go server is running on localhost:8080', {
            fontSize: '14px',
            fill: '#e74c3c'
        });
    }
}

function displayEvaluationResults(result) {
    // Clear previous results
    if (evaluationResults) {
        evaluationResults.destroy();
    }

    const scores = result.adjustedScores || result.scores;
    const axisNames = {
        umami: '旨味',
        aroma: '香り',
        saltiness: '塩味',
        fat: '脂の量',
        sweetness: '甘味',
        spiciness: '刺激',
        originality: '創作性',
        visual: '見た目',
        volume: 'ボリューム',
        harmony: '調和性'
    };

    // Create a table-like display
    const tableX = 650;
    const tableY = 180;
    let currentY = tableY;

    // Header
    evaluationResults = scene.add.text(tableX, currentY, 'Recipe Evaluation Results', {
        fontSize: '16px',
        fill: '#ecf0f1',
        fontWeight: 'bold'
    });
    currentY += 25;

    // Cost information
    scene.add.text(tableX, currentY, `Total Cost: ¥${result.totalCost}`, {
        fontSize: '14px',
        fill: '#f39c12'
    });
    currentY += 30;

    // Table headers
    scene.add.text(tableX, currentY, 'Evaluation Axis', {
        fontSize: '14px',
        fill: '#bdc3c7',
        fontWeight: 'bold'
    });
    scene.add.text(tableX + 120, currentY, 'Score', {
        fontSize: '14px',
        fill: '#bdc3c7',
        fontWeight: 'bold'
    });
    scene.add.text(tableX + 180, currentY, 'Percentage', {
        fontSize: '14px',
        fill: '#bdc3c7',
        fontWeight: 'bold'
    });
    scene.add.text(tableX + 260, currentY, 'Rating', {
        fontSize: '14px',
        fill: '#bdc3c7',
        fontWeight: 'bold'
    });
    currentY += 25;

    // Separator line
    scene.add.text(tableX, currentY, '─'.repeat(40), {
        fontSize: '14px',
        fill: '#7f8c8d'
    });
    currentY += 20;

    // Data rows
    Object.entries(axisNames).forEach(([key, label]) => {
        const score = scores[key];
        const percentage = Math.round((score / 65535) * 100);
        const rating = getRating(percentage);
        const ratingColor = getRatingColor(percentage);

        scene.add.text(tableX, currentY, label, {
            fontSize: '12px',
            fill: '#ecf0f1'
        });
        
        scene.add.text(tableX + 120, currentY, score.toString(), {
            fontSize: '12px',
            fill: '#3498db'
        });
        
        scene.add.text(tableX + 180, currentY, `${percentage}%`, {
            fontSize: '12px',
            fill: '#2ecc71'
        });
        
        scene.add.text(tableX + 260, currentY, rating, {
            fontSize: '12px',
            fill: ratingColor
        });
        
        currentY += 18;
    });
}

function getRating(percentage) {
    if (percentage >= 90) return 'Excellent';
    if (percentage >= 75) return 'Very Good';
    if (percentage >= 60) return 'Good';
    if (percentage >= 40) return 'Average';
    if (percentage >= 25) return 'Poor';
    return 'Very Poor';
}

function getRatingColor(percentage) {
    if (percentage >= 75) return '#2ecc71'; // Green
    if (percentage >= 50) return '#f39c12'; // Orange
    return '#e74c3c'; // Red
}

// Initialize the game
const game = new Phaser.Game(config);