const jwt = require('jsonwebtoken');
const { ApiError } = require('../errors');

function secret() {
  return process.env.JWT_SECRET || 'biblionet-dev-cambiar';
}

function firmar(payload) {
  return jwt.sign(payload, secret(), { expiresIn: '8h' });
}

function requireAuth(req, _res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : '';
  if (!token) return next(new ApiError(401, 'Debe iniciar sesión'));
  try {
    req.usuario = jwt.verify(token, secret());
    next();
  } catch {
    next(new ApiError(401, 'La sesión no es válida o expiró'));
  }
}

function requireRole(...roles) {
  return (req, _res, next) => {
    if (!req.usuario) return next(new ApiError(401, 'Debe iniciar sesión'));
    if (!roles.includes(req.usuario.rol)) {
      return next(new ApiError(403, 'No tiene permiso para esta operación'));
    }
    next();
  };
}

module.exports = { firmar, requireAuth, requireRole };
