// Recipe ingredients data
const INGREDIENTS = {
    noodles: [
        { id: 'thick_noodles', name: '太麺' },
        { id: 'thin_noodles', name: '細麺' },
        { id: 'medium_noodles', name: '中太麺' },
        { id: 'flat_noodles', name: '平打ち麺' }
    ],
    soup: [
        { id: 'chicken_broth', name: '鶏白湯' },
        { id: 'pork_broth', name: '豚骨' },
        { id: 'miso_broth', name: '味噌' },
        { id: 'seafood_broth', name: '魚介系' }
    ],
    sauce: [
        { id: 'shoyu_tare', name: '醤油だれ' },
        { id: 'miso_tare', name: '味噌だれ' },
        { id: 'shio_tare', name: '塩だれ' },
        { id: 'tonkotsu_tare', name: '豚骨だれ' }
    ],
    oil: [
        { id: 'black_garlic_oil', name: '黒マー油' },
        { id: 'scallion_oil', name: 'ネギ油' },
        { id: 'chili_oil', name: 'ラー油' },
        { id: 'sesame_oil', name: 'ごま油' }
    ],
    toppings: [
        { id: 'char_siu', name: 'チャーシュー' },
        { id: 'ajitama', name: '味玉' },
        { id: 'menma', name: 'メンマ' },
        { id: 'nori', name: '海苔' },
        { id: 'corn', name: 'コーン' },
        { id: 'butter', name: 'バター' }
    ],
    presentation: [
        { id: 'black_bowl', name: '黒どんぶり' },
        { id: 'white_bowl', name: '白どんぶり' },
        { id: 'wooden_bowl', name: '木製どんぶり' },
        { id: 'ceramic_bowl', name: '陶器どんぶり' }
    ]
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

function preload() {
    // No assets to preload for this minimal prototype
}

function create() {
    scene = this;
    
    // Title
    this.add.text(600, 50, 'Ramen Recipe Creator', {
        fontSize: '32px',
        fill: '#ecf0f1',
        fontWeight: 'bold'
    }).setOrigin(0.5);

    // Instructions
    this.add.text(600, 90, 'Select ingredients for your ramen recipe:', {
        fontSize: '18px',
        fill: '#bdc3c7'
    }).setOrigin(0.5);

    // Create ingredient selection sections
    createIngredientSection('noodles', '麺', 100, 150);
    createIngredientSection('soup', 'スープ', 100, 220);
    createIngredientSection('sauce', 'かえし', 100, 290);
    createIngredientSection('oil', '香味油', 100, 360);
    createIngredientSection('toppings', '具材', 100, 430);
    createIngredientSection('presentation', '盛り付け', 100, 500);

    // Cooking skill level
    createSkillLevelSection(100, 570);

    // Evaluate button
    const evaluateButton = scene.add.text(600, 650, 'Evaluate Recipe', {
        fontSize: '24px',
        fill: '#2ecc71',
        backgroundColor: '#27ae60',
        padding: { x: 20, y: 10 }
    }).setOrigin(0.5).setInteractive();

    evaluateButton.on('pointerdown', evaluateRecipe);
    evaluateButton.on('pointerover', () => evaluateButton.setTint(0xcccccc));
    evaluateButton.on('pointerout', () => evaluateButton.clearTint());

    // Results area
    scene.add.text(650, 150, 'Evaluation Results:', {
        fontSize: '20px',
        fill: '#ecf0f1',
        fontWeight: 'bold'
    });

    // Initialize with default selections
    selectIngredient('noodles', INGREDIENTS.noodles[0]);
    selectIngredient('soup', INGREDIENTS.soup[0]);
    selectIngredient('sauce', INGREDIENTS.sauce[0]);
    selectIngredient('oil', INGREDIENTS.oil[0]);
    selectIngredient('presentation', INGREDIENTS.presentation[0]);
}

function createIngredientSection(category, label, x, y) {
    // Section label
    scene.add.text(x, y, label + ':', {
        fontSize: '16px',
        fill: '#ecf0f1',
        fontWeight: 'bold'
    });

    // Current selection display
    recipeDisplays[category] = scene.add.text(x + 200, y, 'None selected', {
        fontSize: '14px',
        fill: '#f39c12'
    });

    // Selection buttons
    const ingredients = INGREDIENTS[category];
    const buttonsPerRow = category === 'toppings' ? 3 : 4;
    
    ingredients.forEach((ingredient, index) => {
        const row = Math.floor(index / buttonsPerRow);
        const col = index % buttonsPerRow;
        const buttonX = x + 350 + (col * 120);
        const buttonY = y + (row * 25);

        const button = scene.add.text(buttonX, buttonY, ingredient.name, {
            fontSize: '12px',
            fill: '#3498db',
            backgroundColor: '#2980b9',
            padding: { x: 8, y: 4 }
        }).setInteractive();

        button.on('pointerdown', () => selectIngredient(category, ingredient));
        button.on('pointerover', () => button.setTint(0xcccccc));
        button.on('pointerout', () => button.clearTint());
    });
}

function createSkillLevelSection(x, y) {
    scene.add.text(x, y, 'Cooking Skill Level:', {
        fontSize: '16px',
        fill: '#ecf0f1',
        fontWeight: 'bold'
    });

    recipeDisplays.skillLevel = scene.add.text(x + 200, y, '5.0', {
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

function selectIngredient(category, ingredient) {
    if (category === 'toppings') {
        // Toggle toppings
        const index = currentRecipe.toppings.findIndex(t => t.id === ingredient.id);
        if (index === -1) {
            if (currentRecipe.toppings.length < 3) { // Limit to 3 toppings
                currentRecipe.toppings.push(ingredient);
            }
        } else {
            currentRecipe.toppings.splice(index, 1);
        }
        
        const toppingsText = currentRecipe.toppings.length > 0 
            ? currentRecipe.toppings.map(t => t.name).join(', ')
            : 'None selected';
        recipeDisplays.toppings.setText(toppingsText);
    } else {
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

    // Prepare request body
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

    let resultText = 'Evaluation Results:\n\n';
    resultText += `Total Cost: ¥${result.totalCost}\n\n`;
    
    Object.entries(axisNames).forEach(([key, label]) => {
        const score = scores[key];
        const percentage = Math.round((score / 65535) * 100);
        resultText += `${label}: ${score} (${percentage}%)\n`;
    });

    evaluationResults = scene.add.text(650, 180, resultText, {
        fontSize: '14px',
        fill: '#2ecc71',
        lineSpacing: 5
    });
}

// Initialize the game
const game = new Phaser.Game(config);