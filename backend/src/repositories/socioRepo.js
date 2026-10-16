const { query } = require('../db');

async function listar(q) {
  const params = [];
  let sql = `
    SELECT id_socio, codigo, cedula, nombres, apellidos, correo, telefono, tipo_socio, estado
      FROM sert_socio
  `;
  if (q) {
    params.push(`%${q}%`);
    sql += ` WHERE nombres ILIKE $1 OR apellidos ILIKE $1 OR cedula ILIKE $1 OR codigo ILIKE $1`;
  }
  sql += ' ORDER BY apellidos, nombres';
  const { rows } = await query(sql, params);
  return rows;
}

async function porId(id) {
  const { rows } = await query('SELECT * FROM sert_socio WHERE id_socio = $1', [id]);
  return rows[0] || null;
}

async function crear(datos) {
  const { rows } = await query(
    `INSERT INTO sert_socio (codigo, cedula, nombres, apellidos, correo, telefono, tipo_socio, estado)
     VALUES ($1, $2, $3, $4, $5, $6, $7, COALESCE($8, 'ACTIVO'))
     RETURNING id_socio`,
    [datos.codigo, datos.cedula, datos.nombres, datos.apellidos, datos.correo || null,
      datos.telefono || null, datos.tipo_socio, datos.estado]
  );
  return rows[0].id_socio;
}

async function actualizar(id, datos) {
  const { rowCount } = await query(
    `UPDATE sert_socio
        SET codigo = $2, cedula = $3, nombres = $4, apellidos = $5, correo = $6,
            telefono = $7, tipo_socio = $8, estado = $9
      WHERE id_socio = $1`,
    [id, datos.codigo, datos.cedula, datos.nombres, datos.apellidos, datos.correo || null,
      datos.telefono || null, datos.tipo_socio, datos.estado]
  );
  return rowCount;
}

async function siguienteCodigo() {
  const { rows } = await query(`SELECT COALESCE(MAX(id_socio), 0) + 1 AS n FROM sert_socio`);
  return `S-${String(rows[0].n).padStart(4, '0')}`;
}

module.exports = { listar, porId, crear, actualizar, siguienteCodigo };
