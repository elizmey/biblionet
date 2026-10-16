const { ApiError } = require('../errors');
const reservas = require('../repositories/reservaRepo');

async function crear({ idSocio, idLibro }) {
  if (!idSocio) throw new ApiError(400, 'El lector no está vinculado a un socio');
  if (!idLibro) throw new ApiError(400, 'Indique el libro');
  const previa = await reservas.activa(idSocio, idLibro);
  if (previa) throw new ApiError(409, 'Ya tiene una reserva activa de ese título');
  const copias = await reservas.disponibles(idLibro);
  if (copias > 0) throw new ApiError(400, 'Hay ejemplares disponibles: solicítelo en ventanilla');
  return reservas.crear(idSocio, idLibro);
}

async function cancelar(id, usuario) {
  const reserva = await reservas.porId(id);
  if (!reserva) throw new ApiError(404, 'Reserva no encontrada');
  if (usuario.rol === 'LECTOR' && Number(reserva.id_socio) !== Number(usuario.id_socio)) {
    throw new ApiError(403, 'Solo puede cancelar sus propias reservas');
  }
  if (reserva.estado !== 'ACTIVA') throw new ApiError(400, 'La reserva ya no está activa');
  await reservas.cambiarEstado(id, 'CANCELADA');
}

module.exports = { crear, cancelar };
