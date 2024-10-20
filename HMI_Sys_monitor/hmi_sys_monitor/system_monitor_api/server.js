// server.js

const express = require('express');
const mysql = require('mysql');
const cors = require('cors');
const bodyParser = require('body-parser');

const app = express();
const port = 3000;

// Middleware
app.use(cors());
app.use(bodyParser.json());

// Configuration de la base de données
const db = mysql.createConnection({
    host: 'localhost', // ex: 'localhost'
    user: 'root',
    password: 'Mah010505!',
    database: 'system_monitor'
});

// Connexion à la base de données
db.connect((err) => {
    if (err) {
        console.error('Erreur de connexion à la base de données:', err);
        return;
    }
    console.log('Connecté à la base de données MySQL');
});

// Routes

// Obtenir toutes les configurations
app.get('/configs', (req, res) => {
    const sql = 'SELECT * FROM test_configs';
    db.query(sql, (err, results) => {
        if (err) {
            console.error('Erreur lors de la récupération des configurations:', err);
            res.status(500).send('Erreur serveur');
            return;
        }
        res.json(results);
    });
});

// Ajouter une nouvelle configuration
app.post('/configs', (req, res) => {
    console.log('Données reçues:', req.body); // Ajoute cette ligne
    const { test_id, selected_test, description, parameter, value } = req.body;
  
    // Si 'test_id' est null ou indéfini, attribuer une valeur par défaut ou retourner une erreur
    if (!test_id) {
      return res.status(400).json({ error: "'test_id' est requis." });
    }
  
    const query = `INSERT INTO test_configs (test_id, selected_test, description, parameter, value) VALUES (?, ?, ?, ?, ?)`;
    db.query(query, [test_id, selected_test, description, parameter, value], (err, result) => {
      if (err) {
        console.error("Erreur lors de l'ajout de la configuration:", err);
        return res.status(500).json({ error: "Erreur lors de l'ajout de la configuration." });
      }
      res.status(201).json({ message: "Configuration ajoutée avec succès!" });
    });
  });
  
// Mettre à jour une configuration
app.put('/configs/:id', (req, res) => {
    const { id } = req.params; // Get the id from the request parameters
    const { test_id, selected_test, description, parameter, value } = req.body;

    // Validate input
    if (!selected_test || !description || !parameter || !value) {
        return res.status(400).json({ error: "Tous les champs sont requis." });
    }

    // Use the id directly in the SQL query
    const sql = 'UPDATE test_configs SET test_id = ?, selected_test = ?, description = ?, parameter = ?, value = ? WHERE id = ?';
    db.query(sql, [test_id, selected_test, description, parameter, value, id], (err, result) => {
        if (err) {
            console.error('Erreur lors de la mise à jour de la configuration:', err);
            return res.status(500).json({ error: 'Erreur serveur lors de la mise à jour.' });
        }

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Configuration non trouvée.' });
        }

        res.send('Configuration mise à jour avec succès');
    });
});
// Supprimer une configuration
app.delete('/configs/:id', (req, res) => {
    const { id } = req.params;
    const sql = 'DELETE FROM test_configs WHERE id = ?';
    
    db.query(sql, [id], (err, result) => {
        if (err) {
            console.error('Erreur lors de la suppression de la configuration:', err);
            return res.status(500).json({ error: 'Erreur serveur lors de la suppression.' });
        }

        if (result.affectedRows === 0) {
            return res.status(404).json({ error: 'Configuration non trouvée.' });
        }

        res.send('Configuration supprimée avec succès');
    });
});


// Démarrer le serveur
app.listen(port, () => {
    console.log(`API backend en écoute sur http://localhost:${port}`);
});
