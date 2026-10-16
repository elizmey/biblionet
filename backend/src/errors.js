class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}

function mapDbError(err) {
  if (err instanceof ApiError) return err;
  if (err.code === '23505') return new ApiError(409, 'Ya existe un registro con ese valor único');
  if (err.code === '23514') return new ApiError(400, 'Los datos no cumplen las restricciones de la base');
  if (err.code === '23503') return new ApiError(400, 'La referencia indicada no existe');
  if (err.code === 'P0001' || err.code === '23502') {
    return new ApiError(400, err.message.replace(/^.*ERROR:\s*/, ''));
  }
  return new ApiError(500, err.message || 'Error interno');
}

module.exports = { ApiError, mapDbError };
