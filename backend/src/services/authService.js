const bcrypt = require('bcryptjs');
const { ApiError } = require('../errors');
const { firmar } = require('../middleware/auth');
const { pool, query } = require('../db');
const usuarios = require('../repositories/usuarioRepo');

function publico(usuario) {
  return {
    id_usuario: usuario.id_usuario,
    nombres: usuario.nombres,
    apellidos: usuario.apellidos,
    usuario: usuario.usuario,
    rol: usuario.rol,
    id_rol: usuario.id_rol,
    id_socio: usuario.id_socio,
  };
}

async function login(usuario, clave) {
  if (!usuario || !clave) throw new ApiError(400, 'Indique usuario y contraseña');
  const row = await usuarios.porUsuario(String(usuario).trim());
  if (!row || !row.activo) throw new ApiError(401, 'Usuario o contraseña incorrectos');
  const ok = await bcrypt.compare(String(clave), row.clave_hash);
  if (!ok) throw new ApiError(401, 'Usuario o contraseña incorrectos');
  const datos = publico(row);
  return { token: firmar(datos), usuario: datos };
}

async function registrar(body) {
  const nombres = String(body.nombres || '').trim();
  const apellidos = String(body.apellidos || '').trim();
  const cedula = String(body.cedula || '').trim();
  const correo = String(body.correo || '').trim();
  const telefono = String(body.telefono || '').trim();
  const tipo = String(body.tipo_socio || 'ESTUDIANTE').trim().toUpperCase();
  const usuario = String(body.usuario || '').trim().toLowerCase();
  const clave = String(body.clave || '');

  if (nombres.length < 2 || apellidos.length < 2) throw new ApiError(400, 'Ingresa nombres y apellidos');
  if (!/^\d{10}$/.test(cedula)) throw new ApiError(400, 'La cédula debe tener 10 dígitos');
  if (correo && !/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(correo)) throw new ApiError(400, 'El correo no es válido');
  if (!['ESTUDIANTE', 'DOCENTE'].includes(tipo)) throw new ApiError(400, 'El registro solo admite estudiante o docente');
  if (!/^[a-z0-9._]{4,40}$/.test(usuario)) {
    throw new ApiError(400, 'El usuario debe tener de 4 a 40 caracteres, sin espacios');
  }
  if (clave.length < 6) throw new ApiError(400, 'La contraseña debe tener al menos 6 caracteres');

  if (await usuarios.porUsuario(usuario)) throw new ApiError(409, 'Ese usuario ya está registrado');
  const { rows: cedulas } = await query('SELECT 1 FROM sert_socio WHERE cedula = $1', [cedula]);
  if (cedulas[0]) throw new ApiError(409, 'Ya existe un socio con esa cédula');

  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { rows: roles } = await client.query(`SELECT id_rol FROM sert_rol WHERE nombre = 'LECTOR'`);
    if (!roles[0]) throw new ApiError(500, 'No está configurado el rol de lector');
    const { rows: siguiente } = await client.query('SELECT COALESCE(MAX(id_socio), 0) + 1 AS n FROM sert_socio');
    const codigo = `S-${String(siguiente[0].n).padStart(4, '0')}`;
    const { rows: socio } = await client.query(
      `INSERT INTO sert_socio (codigo, cedula, nombres, apellidos, correo, telefono, tipo_socio)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING id_socio`,
      [codigo, cedula, nombres, apellidos, correo || null, telefono || null, tipo]
    );
    const claveHash = await bcrypt.hash(clave, 10);
    await client.query(
      `INSERT INTO sert_usuario (id_rol, id_socio, nombres, apellidos, usuario, clave_hash)
       VALUES ($1, $2, $3, $4, $5, $6)`,
      [roles[0].id_rol, socio[0].id_socio, nombres, apellidos, usuario, claveHash]
    );
    await client.query('COMMIT');
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }

  return login(usuario, clave);
}

module.exports = { login, publico, registrar };
