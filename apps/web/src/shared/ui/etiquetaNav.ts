// Corte discrecional de presentación; la ruta y el nombre accesible no cambian.
// Compartido por navegación lateral e inferior (contrato Kiwi MH-NAV-05).
export const etiquetaNav = (texto: string) =>
  texto.replace("Fermentación", "Fermenta\u00adción").replace("Destilación", "Destila\u00adción")
