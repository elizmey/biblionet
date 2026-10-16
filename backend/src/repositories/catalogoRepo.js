const { query } = require('../db');

async function buscarLibros({ q, categoria, disponibles }) {
  const params = [];
  let sql = `
    SELECT l.id_libro, l.isbn, l.titulo, l.anio_publicacion,
           l.id_categoria, c.nombre AS categoria,
           l.id_editorial, e.nombre AS editorial,
           COALESCE(string_agg(a.nombres || ' ' || a.apellidos, ', ' ORDER BY a.apellidos), '') AS autores,
           COALESCE(array_agg(a.id_autor) FILTER (WHERE a.id_autor IS NOT NULL), '{}') AS id_autores,
           (SELECT count(*)::int FROM sert_ejemplar ej WHERE ej.id_libro = l.id_libro AND ej.estado <> 'BAJA') AS total,
           (SELECT count(*)::int FROM sert_ejemplar ej WHERE ej.id_libro = l.id_libro AND ej.estado = 'DISPONIBLE') AS disponibles
      FROM sert_libro l
      JOIN sert_categoria c ON c.id_categoria = l.id_categoria
      JOIN sert_editorial e ON e.id_editorial = l.id_editorial
      LEFT JOIN sert_libro_autor la ON la.id_libro = l.id_libro
      LEFT JOIN sert_autor a ON a.id_autor = la.id_autor
     WHERE 1 = 1
  `;
  if (q) {
    params.push(`%${q}%`);
    sql += ` AND (l.titulo ILIKE $${params.length} OR l.isbn ILIKE $${params.length}
              OR (a.nombres || ' ' || a.apellidos) ILIKE $${params.length})`;
  }
  if (categoria) {
    params.push(Number(categoria));
    sql += ` AND l.id_categoria = $${params.length}`;
  }
  sql += ' GROUP BY l.id_libro, c.nombre, e.nombre';
  if (disponibles === '1' || disponibles === 'true' || disponibles === 'si') {
    sql += ' HAVING (SELECT count(*) FROM sert_ejemplar ej WHERE ej.id_libro = l.id_libro AND ej.estado = \'DISPONIBLE\') > 0';
  }
  sql += ' ORDER BY l.titulo';
  const { rows } = await query(sql, params);
  return rows;
}

async function crearLibro({ isbn, titulo, anio_publicacion, id_categoria, id_editorial, autores }) {
  const { rows } = await query(
    `INSERT INTO sert_libro (isbn, titulo, anio_publicacion, id_categoria, id_editorial)
     VALUES ($1, $2, $3, $4, $5) RETURNING id_libro`,
    [isbn, titulo, anio_publicacion, id_categoria, id_editorial]
  );
  const id = rows[0].id_libro;
  for (const idAutor of autores || []) {
    await query(
      'INSERT INTO sert_libro_autor (id_libro, id_autor) VALUES ($1, $2) ON CONFLICT DO NOTHING',
      [id, idAutor]
    );
  }
  return id;
}

async function actualizarLibro(id, datos) {
  await query(
    `UPDATE sert_libro
        SET isbn = $2, titulo = $3, anio_publicacion = $4, id_categoria = $5, id_editorial = $6
      WHERE id_libro = $1`,
    [id, datos.isbn, datos.titulo, datos.anio_publicacion, datos.id_categoria, datos.id_editorial]
  );
  if (Array.isArray(datos.autores)) {
    await query('DELETE FROM sert_libro_autor WHERE id_libro = $1', [id]);
    for (const idAutor of datos.autores) {
      await query('INSERT INTO sert_libro_autor (id_libro, id_autor) VALUES ($1, $2)', [id, idAutor]);
    }
  }
}

async function listarEjemplares(idLibro) {
  const params = [];
  let sql = `
    SELECT e.id_ejemplar, e.id_libro, e.codigo_barras, e.ubicacion, e.estado, l.titulo
      FROM sert_ejemplar e
      JOIN sert_libro l ON l.id_libro = e.id_libro
  `;
  if (idLibro) {
    params.push(Number(idLibro));
    sql += ` WHERE e.id_libro = $1`;
  }
  sql += ' ORDER BY e.codigo_barras';
  const { rows } = await query(sql, params);
  return rows;
}

async function crearEjemplar({ id_libro, codigo_barras, ubicacion, estado }) {
  const { rows } = await query(
    `INSERT INTO sert_ejemplar (id_libro, codigo_barras, ubicacion, estado)
     VALUES ($1, $2, $3, COALESCE($4, 'DISPONIBLE')) RETURNING id_ejemplar`,
    [id_libro, codigo_barras, ubicacion, estado || null]
  );
  return rows[0].id_ejemplar;
}

async function actualizarEjemplar(id, { ubicacion, estado }) {
  const { rowCount } = await query(
    `UPDATE sert_ejemplar
        SET ubicacion = COALESCE($2, ubicacion),
            estado = COALESCE($3, estado)
      WHERE id_ejemplar = $1
        AND estado <> 'PRESTADO'`,
    [id, ubicacion || null, estado || null]
  );
  return rowCount;
}

async function crearCategoria(nombre) {
  const { rows } = await query(
    'INSERT INTO sert_categoria (nombre) VALUES ($1) RETURNING id_categoria',
    [nombre]
  );
  return rows[0].id_categoria;
}

async function crearAutor({ nombres, apellidos }) {
  const { rows } = await query(
    'INSERT INTO sert_autor (nombres, apellidos) VALUES ($1, $2) RETURNING id_autor',
    [nombres, apellidos]
  );
  return rows[0].id_autor;
}

async function crearEditorial({ nombre, pais }) {
  const { rows } = await query(
    'INSERT INTO sert_editorial (nombre, pais) VALUES ($1, $2) RETURNING id_editorial',
    [nombre, pais]
  );
  return rows[0].id_editorial;
}

async function categorias() {
  const { rows } = await query('SELECT id_categoria, nombre FROM sert_categoria ORDER BY nombre');
  return rows;
}

async function autores() {
  const { rows } = await query(
    `SELECT id_autor, nombres, apellidos FROM sert_autor ORDER BY apellidos, nombres`
  );
  return rows;
}

async function editoriales() {
  const { rows } = await query(
    'SELECT id_editorial, nombre, pais FROM sert_editorial ORDER BY nombre'
  );
  return rows;
}

module.exports = {
  buscarLibros, crearLibro, actualizarLibro, listarEjemplares, crearEjemplar, actualizarEjemplar,
  categorias, autores, editoriales, crearCategoria, crearAutor, crearEditorial,
};
