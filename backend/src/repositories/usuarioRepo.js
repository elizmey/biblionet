const { query } = require('../db');

async function porUsuario(usuario) {
  const { rows } = await query(
    `SELECT u.id_usuario, u.id_rol, u.nombres, u.apellidos, u.usuario, u.clave_hash,
            u.activo, u.id_socio, r.nombre AS rol
       FROM sert_usuario u
       JOIN sert_rol r ON r.id_rol = u.id_rol
      WHERE u.usuario = $1`,
    [usuario]
  );
  return rows[0] || null;
}

async function listar() {
  const { rows } = await query(
    `SELECT u.id_usuario, u.nombres, u.apellidos, u.usuario, u.activo, u.id_socio,
            u.id_rol, r.nombre AS rol
       FROM sert_usuario u
       JOIN sert_rol r ON r.id_rol = u.id_rol
      ORDER BY u.id_usuario`
  );
  return rows;
}

async function roles() {
  const { rows } = await query('SELECT id_rol, nombre, descripcion FROM sert_rol ORDER BY id_rol');
  return rows;
}

async function crear({ id_rol, nombres, apellidos, usuario, clave_hash, id_socio }) {
  const { rows } = await query(
    `INSERT INTO sert_usuario (id_rol, nombres, apellidos, usuario, clave_hash, id_socio)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING id_usuario`,
    [id_rol, nombres, apellidos, usuario, clave_hash, id_socio || null]
  );
  return rows[0].id_usuario;
}

async function actualizar(id, { id_rol, nombres, apellidos, activo, id_socio, clave_hash }) {
  const { rowCount } = await query(
    `UPDATE sert_usuario
        SET id_rol = $2, nombres = $3, apellidos = $4, activo = $5, id_socio = $6,
            clave_hash = COALESCE($7, clave_hash)
      WHERE id_usuario = $1`,
    [id, id_rol, nombres, apellidos, activo, id_socio || null, clave_hash || null]
  );
  return rowCount;
}

async function parametros() {
  const { rows } = await query('SELECT clave, valor, detalle FROM sert_parametro ORDER BY clave');
  return rows;
}

async function guardarParametro(clave, valor) {
  await query('UPDATE sert_parametro SET valor = $2 WHERE clave = $1', [clave, String(valor)]);
}

module.exports = { porUsuario, listar, roles, crear, actualizar, parametros, guardarParametro };
