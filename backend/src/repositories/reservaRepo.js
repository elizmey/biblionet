const { query } = require('../db');

async function listar(idSocio) {
  const params = [];
  let sql = `
    SELECT r.id_reserva, r.id_socio, r.id_libro, r.fecha_reserva, r.fecha_limite, r.estado,
           s.nombres || ' ' || s.apellidos AS socio, l.titulo
      FROM sert_reserva r
      JOIN sert_socio s ON s.id_socio = r.id_socio
      JOIN sert_libro l ON l.id_libro = r.id_libro
  `;
  if (idSocio) {
    params.push(idSocio);
    sql += ' WHERE r.id_socio = $1';
  }
  sql += ' ORDER BY r.fecha_reserva DESC';
  const { rows } = await query(sql, params);
  return rows;
}

async function disponibles(idLibro) {
  const { rows } = await query(
    `SELECT count(*)::int AS n FROM sert_ejemplar WHERE id_libro = $1 AND estado = 'DISPONIBLE'`,
    [idLibro]
  );
  return rows[0].n;
}

async function activa(idSocio, idLibro) {
  const { rows } = await query(
    `SELECT id_reserva FROM sert_reserva
      WHERE id_socio = $1 AND id_libro = $2 AND estado = 'ACTIVA'`,
    [idSocio, idLibro]
  );
  return rows[0] || null;
}

async function crear(idSocio, idLibro) {
  const { rows } = await query(
    `INSERT INTO sert_reserva (id_socio, id_libro, fecha_limite)
     VALUES ($1, $2, CURRENT_DATE + (SELECT valor::int FROM sert_parametro WHERE clave = 'DIAS_RESERVA'))
     RETURNING id_reserva, fecha_limite`,
    [idSocio, idLibro]
  );
  return rows[0];
}

async function cambiarEstado(id, estado) {
  const { rowCount } = await query(
    `UPDATE sert_reserva SET estado = $2 WHERE id_reserva = $1`,
    [id, estado]
  );
  return rowCount;
}

async function porId(id) {
  const { rows } = await query('SELECT * FROM sert_reserva WHERE id_reserva = $1', [id]);
  return rows[0] || null;
}

module.exports = { listar, disponibles, activa, crear, cambiarEstado, porId };
