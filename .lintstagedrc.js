module.exports = {
  // JavaScript/TypeScript files - utiliser npx pour trouver eslint localement
  '*.{js,jsx}': [
    'npx eslint --fix'
  ],
  
  // Note: Prettier peut être ajouté si nécessaire
  // '*.json': ['prettier --write'],
  // '*.md': ['prettier --write']
};

