const bcrypt = require('bcryptjs');
const { ApiError } = require('../errors');
const usuarios = require('../repositories/usuarioRepo');

const CLAVES = ['DIAS_PRESTAMO', 'MAX_PRESTAMOS', 'MULTA_DIA', 'DIAS_RESERVA'];

async function crear(datos) {
  if (!datos.usuario || !datos.clave || !datos.nombres || !datos.apellidos || !datos.id_rol) {
    throw new ApiError(400, 'Complete usuario, contraseña, nombre y rol');
  }
  const clave_hash = await bcrypt.hash(String(datos.clave), 10);
  return usuarios.crear({ ...datos, clave_hash });
}

async function actualizar(id, datos) {
  if (!datos.nombres || !datos.apellidos || !datos.id_rol) {
    throw new ApiError(400, 'Complete nombre y rol');
  }
  const clave_hash = datos.clave ? await bcrypt.hash(String(datos.clave), 10) : null;
  const n = await usuarios.actualizar(id, { ...datos, clave_hash, activo: datos.activo !== false });
  if (!n) throw new ApiError(404, 'Usuario no encontrado');
}

async function guardarParametros(body) {
  for (const clave of CLAVES) {
    if (body[clave] === undefined || body[clave] === null || body[clave] === '') continue;
    const valor = String(body[clave]).trim();
    if (clave === 'MULTA_DIA') {
      if (!(Number(valor) > 0)) throw new ApiError(400, 'La tarifa de multa debe ser mayor que cero');
    } else if (!(Number(valor) >= 1)) {
      throw new ApiError(400, `${clave} debe ser un número mayor que cero`);
    }
    await usuarios.guardarParametro(clave, valor);
  }
  return usuarios.parametros();
}

module.exports = { crear, actualizar, guardarParametros };
