const { ApiError } = require('../errors');
const socios = require('../repositories/socioRepo');
const multas = require('../repositories/multaRepo');
const prestamos = require('../repositories/prestamoRepo');

async function registrar({ idSocio, idUsuario, ejemplares }) {
  const ids = [...new Set((ejemplares || []).map(Number).filter(Boolean))];
  if (!idSocio || ids.length === 0) {
    throw new ApiError(400, 'Indique el socio y al menos un ejemplar');
  }
  const socio = await socios.porId(idSocio);
  if (!socio) throw new ApiError(404, 'Socio no encontrado');
  if (socio.estado !== 'ACTIVO') throw new ApiError(400, 'El socio no está habilitado');
  if (await multas.pendientesDeSocio(idSocio) > 0) {
    throw new ApiError(400, 'El socio tiene multas pendientes');
  }
  if (await prestamos.vencidosDeSocio(idSocio) > 0) {
    throw new ApiError(400, 'El socio tiene préstamos vencidos');
  }
  const id = await prestamos.registrar({ idSocio, idUsuario, ejemplares: ids });
  return id;
}

async function devolver({ idPrestamo, idDetalle }) {
  const det = await prestamos.detalle(idDetalle);
  if (!det || Number(det.id_prestamo) !== Number(idPrestamo)) {
    throw new ApiError(404, 'El detalle no pertenece a ese préstamo');
  }
  if (det.fecha_devolucion) throw new ApiError(400, 'Ese ejemplar ya fue devuelto');
  const monto = await prestamos.devolver(idDetalle);
  return { monto: Number(monto) };
}

module.exports = { registrar, devolver };
