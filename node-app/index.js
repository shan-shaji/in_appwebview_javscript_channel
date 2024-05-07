const express = require('express');

const app = express();

app.set('view engine', 'ejs');
app.use(express.static('public'));

app.get('/', (_, res) => {
  res.render('index');
});

const PORT = process.env.PORT || 4000;

app.listen(PORT, () => {
  console.log(`Server started on http://localhost:${PORT}`);
});
