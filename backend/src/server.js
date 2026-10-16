const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const { query } = require('./db');
const { ApiError, mapDbError } = require('./errors');
const { requireAuth, requireRole } = require('./middleware/auth');
const { preparar } = require('./bootstrap');

const authService = require('./services/authService');
const prestamoService = require('./services/prestamoService');
const reservaService = require('./services/reservaService');
const usuarioService = require('./services/usuarioService');

const catalogo = require('./repositories/catalogoRepo');
const socios = require('./repositories/socioRepo');
const prestamos = require('./repositories/prestamoRepo');
const multas = require('./repositories/multaRepo');
const reservas = require('./repositories/reservaRepo');
const usuarios = require('./repositories/usuarioRepo');
const panel = require('./repositories/panelRepo');

const app = express();
const PORT = process.env.PORT || 3000;
const staff = requireRole('ADMINISTRADOR', 'BIBLIOTECARIO');
const admin = requireRole('ADMINISTRADOR');

app.use(helmet());
app.use(cors());
app.use(express.json());

function asyncRoute(handler) {
  return (req, res, next) => Promise.resolve(handler(req, res, next)).catch((err) => next(mapDbError(err)));
}

app.get('/', (_req, res) => {
  res.type('html').send(
    '<!doctype html><meta charset="utf-8"><title>Biblionet API</title>'
    + '<body style="font-family:sans-serif;background:#F6F3FB;color:#4B2A7B">'
    + '<h1>Biblionet API</h1><p>El cliente es la aplicación Flutter de la carpeta app.</p></body>'
  );
});

app.get('/api/v1/health', asyncRoute(async (_req, res) => {
  await query('SELECT 1');
  res.json({ ok: true, servicio: 'biblionet-api' });
}));

app.post('/api/v1/auth/login', asyncRoute(async (req, res) => {
  const resultado = await authService.login(req.body.usuario, req.body.clave);
  res.json(resultado);
}));

app.post('/api/v1/auth/registro', asyncRoute(async (req, res) => {
  const resultado = await authService.registrar(req.body);
  res.status(201).json(resultado);
}));

app.get('/api/v1/auth/me', requireAuth, (req, res) => {
  res.json({ usuario: req.usuario });
});

app.get('/api/v1/panel', requireAuth, staff, asyncRoute(async (_req, res) => {
  res.json(await panel.resumen());
}));

app.get('/api/v1/libros', requireAuth, asyncRoute(async (req, res) => {
  res.json(await catalogo.buscarLibros({
    q: req.query.q || '',
    categoria: req.query.categoria,
    disponibles: req.query.disponibles,
  }));
}));

app.post('/api/v1/libros', requireAuth, staff, asyncRoute(async (req, res) => {
  const id = await catalogo.crearLibro(req.body);
  res.status(201).json({ id_libro: id });
}));

app.put('/api/v1/libros/:id', requireAuth, staff, asyncRoute(async (req, res) => {
  await catalogo.actualizarLibro(Number(req.params.id), req.body);
  res.json({ ok: true });
}));

app.get('/api/v1/ejemplares', requireAuth, asyncRoute(async (req, res) => {
  res.json(await catalogo.listarEjemplares(req.query.id_libro));
}));

app.post('/api/v1/ejemplares', requireAuth, staff, asyncRoute(async (req, res) => {
  const id = await catalogo.crearEjemplar(req.body);
  res.status(201).json({ id_ejemplar: id });
}));

app.put('/api/v1/ejemplares/:id', requireAuth, staff, asyncRoute(async (req, res) => {
  const n = await catalogo.actualizarEjemplar(Number(req.params.id), req.body);
  if (!n) throw new ApiError(400, 'No se puede modificar un ejemplar prestado');
  res.json({ ok: true });
}));

app.get('/api/v1/categorias', requireAuth, asyncRoute(async (_req, res) => {
  res.json(await catalogo.categorias());
}));

app.get('/api/v1/autores', requireAuth, asyncRoute(async (_req, res) => {
  res.json(await catalogo.autores());
}));

app.get('/api/v1/editoriales', requireAuth, asyncRoute(async (_req, res) => {
  res.json(await catalogo.editoriales());
}));

app.post('/api/v1/categorias', requireAuth, staff, asyncRoute(async (req, res) => {
  const id = await catalogo.crearCategoria(req.body.nombre);
  res.status(201).json({ id_categoria: id });
}));

app.post('/api/v1/autores', requireAuth, staff, asyncRoute(async (req, res) => {
  const id = await catalogo.crearAutor(req.body);
  res.status(201).json({ id_autor: id });
}));

app.post('/api/v1/editoriales', requireAuth, staff, asyncRoute(async (req, res) => {
  const id = await catalogo.crearEditorial(req.body);
  res.status(201).json({ id_editorial: id });
}));

app.get('/api/v1/socios', requireAuth, staff, asyncRoute(async (req, res) => {
  res.json(await socios.listar(req.query.q || ''));
}));

app.post('/api/v1/socios', requireAuth, staff, asyncRoute(async (req, res) => {
  const datos = { ...req.body };
  if (!datos.codigo || !String(datos.codigo).trim()) datos.codigo = await socios.siguienteCodigo();
  const id = await socios.crear(datos);
  res.status(201).json({ id_socio: id });
}));

app.put('/api/v1/socios/:id', requireAuth, staff, asyncRoute(async (req, res) => {
  const n = await socios.actualizar(Number(req.params.id), req.body);
  if (!n) throw new ApiError(404, 'Socio no encontrado');
  res.json({ ok: true });
}));

app.get('/api/v1/prestamos/mios', requireAuth, requireRole('LECTOR'), asyncRoute(async (req, res) => {
  if (!req.usuario.id_socio) throw new ApiError(400, 'El lector no está vinculado a un socio');
  res.json(await prestamos.listar({ idSocio: req.usuario.id_socio }));
}));

app.get('/api/v1/prestamos', requireAuth, staff, asyncRoute(async (_req, res) => {
  res.json(await prestamos.listar());
}));

app.post('/api/v1/prestamos', requireAuth, staff, asyncRoute(async (req, res) => {
  const id = await prestamoService.registrar({
    idSocio: Number(req.body.id_socio),
    idUsuario: req.usuario.id_usuario,
    ejemplares: req.body.ejemplares,
  });
  res.status(201).json({ id_prestamo: id });
}));

app.post('/api/v1/prestamos/:id/detalles/:idd/devolucion', requireAuth, staff, asyncRoute(async (req, res) => {
  const resultado = await prestamoService.devolver({
    idPrestamo: Number(req.params.id),
    idDetalle: Number(req.params.idd),
  });
  res.json(resultado);
}));

app.get('/api/v1/reservas', requireAuth, asyncRoute(async (req, res) => {
  const idSocio = req.usuario.rol === 'LECTOR' ? req.usuario.id_socio : undefined;
  res.json(await reservas.listar(idSocio));
}));

app.post('/api/v1/reservas', requireAuth, asyncRoute(async (req, res) => {
  const idSocio = req.usuario.rol === 'LECTOR' ? req.usuario.id_socio : Number(req.body.id_socio);
  const creada = await reservaService.crear({ idSocio, idLibro: Number(req.body.id_libro) });
  res.status(201).json(creada);
}));

app.patch('/api/v1/reservas/:id', requireAuth, asyncRoute(async (req, res) => {
  if (req.body.estado !== 'CANCELADA') throw new ApiError(400, 'Solo se puede cancelar la reserva');
  await reservaService.cancelar(Number(req.params.id), req.usuario);
  res.json({ ok: true });
}));

app.get('/api/v1/multas/mias', requireAuth, requireRole('LECTOR'), asyncRoute(async (req, res) => {
  const filas = await multas.listarDeSocio(req.usuario.id_socio);
  const total = filas
    .filter((m) => m.estado === 'PENDIENTE')
    .reduce((suma, m) => suma + Number(m.monto), 0);
  res.json({ total, multas: filas });
}));

app.get('/api/v1/multas', requireAuth, staff, asyncRoute(async (_req, res) => {
  const parametros = await usuarios.parametros();
  const tarifa = parametros.find((p) => p.clave === 'MULTA_DIA');
  res.json({ tarifa: tarifa ? tarifa.valor : '0.25', multas: await multas.listar() });
}));

app.patch('/api/v1/multas/:id', requireAuth, staff, asyncRoute(async (req, res) => {
  if (req.body.estado !== 'PAGADA') throw new ApiError(400, 'Indique el pago de la multa');
  const n = await multas.pagar(Number(req.params.id));
  if (!n) throw new ApiError(404, 'La multa no está pendiente');
  res.json({ ok: true });
}));

app.get('/api/v1/reportes/mas-prestados', requireAuth, staff, asyncRoute(async (req, res) => {
  const filas = await panel.masPrestados();
  const csv = req.query.formato === 'csv' || String(req.headers.accept || '').includes('text/csv');
  if (csv) {
    const cuerpo = ['titulo,veces', ...filas.map((f) => `"${String(f.titulo).replace(/"/g, '""')}",${f.veces}`)];
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition', 'attachment; filename="mas_prestados.csv"');
    res.send(cuerpo.join('\n'));
    return;
  }
  res.json(filas);
}));

app.get('/api/v1/parametros', requireAuth, admin, asyncRoute(async (_req, res) => {
  res.json(await usuarios.parametros());
}));

app.put('/api/v1/parametros', requireAuth, admin, asyncRoute(async (req, res) => {
  res.json(await usuarioService.guardarParametros(req.body));
}));

app.get('/api/v1/usuarios', requireAuth, admin, asyncRoute(async (_req, res) => {
  res.json({ usuarios: await usuarios.listar(), roles: await usuarios.roles() });
}));

app.post('/api/v1/usuarios', requireAuth, admin, asyncRoute(async (req, res) => {
  const id = await usuarioService.crear(req.body);
  res.status(201).json({ id_usuario: id });
}));

app.put('/api/v1/usuarios/:id', requireAuth, admin, asyncRoute(async (req, res) => {
  await usuarioService.actualizar(Number(req.params.id), req.body);
  res.json({ ok: true });
}));

app.use((err, _req, res, _next) => {
  const status = err.status || 500;
  res.status(status).json({ error: err.message || 'Error interno' });
});

preparar().finally(() => {
  app.listen(PORT, () => {
    console.log(`Biblionet API en http://localhost:${PORT}`);
  });
});

module.exports = app;
