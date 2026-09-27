import sys
sys.stdout.reconfigure(encoding="utf-8")
from pathlib import Path
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, PageBreak
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from xml.sax.saxutils import escape

OUT=Path('output/pdf'); OUT.mkdir(parents=True,exist_ok=True)
pages=[
('Validar el negocio antes de ampliar el producto', '01 / PLAN DE CAMPO', '''
# KAZA · Guion unificado para el prehackatón
Una guía para entrevistar, observar y decidir. Basada en los dos guiones compartidos y en la diapositiva de Incuba Unión 3.0: supuesto riesgoso, experimento, prueba de concepto y preparación del sábado.
## Qué cambiamos de los originales
Conservamos los relatos de experiencias, los canales actuales, la comparación de propiedades y el seguimiento comercial. Reducimos repeticiones y dejamos las repreguntas como opcionales. Sustituimos preguntas que dan por hecho una dificultad por exploraciones neutrales. Separamos agentes de propietarios particulares y añadimos evidencia de negocio.
## Hipótesis de trabajo, todavía no conclusiones
H1 · Personas con búsqueda reciente invierten esfuerzo relevante en obtener información de inmuebles antes de decidir a cuáles contactar o visitar.
H2 · Agentes activos tienen dificultades recurrentes para gestionar información o dar seguimiento; ya dedican recursos a resolverlas.
H3 · Un grupo de agentes aportaría inventario actualizado y asumiría un compromiso concreto por una mejora comprobable. El agente o la inmobiliaria es un posible pagador; hay que comprobar quién decide y qué compra.
## Supuesto más riesgoso propuesto
Que los agentes encuentren valor suficiente para aportar propiedades, mantenerlas actualizadas y después pagar, incluso cuando ya cuentan con sus canales habituales. Si no hay oferta útil y vigente, un mapa por sí solo no sostiene el negocio.
Si las entrevistas muestran que el problema principal es otro, cambiar esta prioridad antes de construir más funciones.
## Alcance de una jornada
Meta operativa propuesta: 6 personas con búsquedas en los últimos 6 meses y 6 agentes que hayan atendido consultas en los últimos 30 días. Si se alcanza a propietarios particulares, analizarlos por separado. No mezclar alquiler, compra y anticrético al interpretar resultados.
Esta muestra sirve para encontrar señales y contradicciones; no representa estadísticamente al mercado. Registrar rechazos y evitar entrevistar solo a amigos o personas entusiasmadas con tecnología.
## Duración y recorrido
Entrevista principal: 12-15 minutos. Prueba opcional: 5 minutos adicionales, con permiso. Preparar dos personas por equipo cuando sea posible: una conversa y otra registra.
Leer las preguntas principales de la página del segmento. Usar solo una o dos repreguntas donde aparezca un caso útil; no completar todas como un cuestionario obligatorio.
'''),
('Apertura y reglas para escuchar', '02 / PARA EL ENTREVISTADOR', '''
## Introducción para leer
“Hola, soy [nombre]. Participamos en Incuba Unión Tecnológico 3.0 de Emprender Futuro. Estamos investigando cómo las personas buscan y ofrecen inmuebles. Quisiéramos conocer una experiencia tuya reciente. La conversación dura unos 12 a 15 minutos. No estamos intentando venderte nada; nos sirve tanto lo que funciona como lo que no. Podés omitir cualquier pregunta o terminar cuando quieras.”
## Consentimiento, sin asumir la respuesta
“¿Está bien si tomo notas para analizarlas con el equipo del proyecto?” Esperar respuesta.
Solo si desean grabar: “¿Me autorizás a grabar esta conversación para el análisis interno del proyecto? Si preferís que no, podemos continuar tomando notas.” Registrar sí o no antes de activar la grabación.
Explicar quién tendrá acceso y acordar cuándo se borrará la grabación. No publicar voz, imagen o identidad en el pitch sin un permiso adicional específico. No solicitar documentos, contratos ni conversaciones identificables de clientes.
## Filtro y contexto · 1 minuto
Buscador: “¿Cuándo fue tu búsqueda más reciente? ¿Buscabas comprar, alquilar o anticrético? ¿En qué ciudad? ¿Participaste vos en la decisión?”
Agente: “¿Qué rol tenés y cuándo atendiste tu última consulta? ¿Trabajás por cuenta propia o para una inmobiliaria? ¿Cuántas propiedades activas manejás aproximadamente?”
Si no tiene una experiencia reciente, registrar su perspectiva como exploratoria; no contarla en la muestra principal.
## Cómo profundizar sin sugerir la respuesta
“Contame un caso concreto.” / “¿Qué pasó después?” / “¿Cómo lo resolviste?” / “¿Cuánto tiempo o dinero te llevó, aproximadamente?” / “¿Qué parte sí funcionó?”
Separar lo espontáneo de lo obtenido con una repregunta. Si no recuerda cantidades, anotar “no recuerda”; no completar ni inventar el dato.
## Evitar estas trampas
No preguntar: “¿Te frustran las publicaciones falsas?” Preguntar: “¿Qué pasó entre ver el anuncio y decidir si avanzabas?”
No preguntar: “¿Perdiste clientes por no usar CRM?” Preguntar: “¿Qué ocurrió con esa consulta y cómo sabés cuál fue el resultado?”
No usar “¿Te gusta?” o “¿Lo usarías?” como prueba de demanda. Pedir una tarea observable o acordar un siguiente paso, aceptando un no sin insistir.
## Versión corta · Si solo hay 7 minutos
Hacer filtro, preguntas 1, 3 y 5 del segmento y cierre. Registrar que fue entrevista corta. No apurar una demostración ni comparar sus respuestas ausentes como si fueran negativas.
'''),
('Personas que buscan un inmueble', '03 / GUION A · 12-15 MINUTOS', '''
## 1. Reconstruir la última búsqueda
“Contame tu búsqueda más reciente de un inmueble: ¿qué necesitabas y qué hiciste desde que empezaste hasta donde llegaste?”
Repregunta opcional: “¿Cuándo fue, qué medios usaste y cómo terminó o en qué punto estás?” Escuchar primero sin mencionar KAZA, mapas ni problemas específicos.
## 2. Entender los canales y lo que ya funciona
“¿Cuál de esos medios te sirvió más? Contame una ocasión concreta en la que te ayudó.”
Repregunta: “¿Por qué empezaste por ese medio? ¿Qué te hizo seguir usándolo o buscar en otro?” Registrar fortalezas del competidor o alternativa actual.
## 3. Seguir una propiedad concreta
“Elegí una propiedad que te interesó. ¿Qué hiciste desde que viste el anuncio hasta decidir si contactabas, visitabas o descartabas?”
Repregunta: “¿Qué información buscaste y cómo la obtuviste? ¿Qué fue sencillo y qué, si algo, te costó?” Si aparece un obstáculo: “¿Qué consecuencia tuvo y cuánto esfuerzo te llevó?”
## 4. Comparación, ubicación y confianza
“¿Cómo elegiste entre las opciones que tenías? Contame qué te hizo seguir con una o descartarla.”
Si falta contexto: “¿Qué necesitabas saber de la zona y cómo lo averiguaste?” Si menciona dudas: “¿Qué hiciste para comprobar la información?” No enumerar problemas de precio, disponibilidad o fotos antes de que relate su caso.
## 5. Frecuencia, impacto y solución actual
“De lo que me contaste, ¿qué parte te exigió más esfuerzo, si hubo alguna? ¿Qué hiciste para resolverla?”
Repregunta: “¿En cuántas de las opciones que revisaste ocurrió algo parecido? ¿Recordás cuántas revisaste en total? ¿Gastaste en traslados, ayuda o algún servicio? ¿Cuánto aproximadamente?” No convertir tiempo invertido en pérdida económica sin evidencia.
## 6. Prioridad y evidencia contraria
“¿Qué fue lo que más influyó en que pudieras o no avanzar? ¿Qué parte de tu forma actual de buscar conservarías?”
Repregunta: “¿Eso pesó más que las otras dificultades que mencionaste? ¿Por qué?” Si encontró rápido lo que necesitaba, profundizar en cómo lo logró.
## Cierre de descubrimiento
“Dejame comprobar si entendí: [resumir con sus palabras el proceso, la dificultad o su ausencia y la consecuencia]. ¿Qué entendí mal o qué me falta?”
Luego pasar a la prueba opcional de la página 5. Si no hay tiempo, agradecer y pedir permiso separado para un contacto futuro.
## Qué registrar
Canal usado, fecha del caso, operación, resultado, información buscada, dificultad espontánea, frecuencia recordada, esfuerzo, alternativa actual y qué funciona bien. Diferenciar obstáculo para encontrar información de una restricción de presupuesto u oferta que la app quizá no pueda resolver.
'''),
('Agentes, inmobiliarias y propietarios', '04 / GUION B · 12-15 MINUTOS', '''
## 1. Reconstruir una operación real
“Elegí una propiedad que hayas trabajado recientemente. ¿Cómo la captaste, dónde la publicaste y qué pasó con las consultas hasta hoy?”
Repregunta: “¿Qué canal produjo contactos y cuál produjo visitas o una operación? ¿Cómo lo registrás?” No equiparar muchas consultas con buenos resultados.
## 2. Observar organización y seguimiento
“Pensá en la última consulta que recibiste: ¿qué hiciste después y cómo decidiste el siguiente paso?”
Repregunta: “¿Dónde quedó registrada? Si te resulta cómodo, ¿podés mostrar el proceso con datos ocultos o un ejemplo ficticio?” No pedir acceso a chats ni nombres de clientes.
## 3. Detectar fricción y consecuencia
“¿Qué parte de ese trabajo requirió más esfuerzo? Contame la última vez que ocurrió y cómo lo resolviste.”
Repregunta: “¿Cuántas veces pasó en los últimos 30 días? ¿Qué consecuencia observaste?” Si cree que perdió una oportunidad: “¿Cómo lo supiste? ¿Podría haber otra explicación?”
## 4. Mantener inventario confiable
“Contame la última vez que cambió el precio o la disponibilidad de una propiedad. ¿Quién se enteró, qué actualizaron y cuánto llevó?”
Repregunta: “¿Quién autoriza publicar esa información? ¿Qué datos preferís no mostrar públicamente?” Si no tuvo cambios recientes, registrar esa ausencia y preguntar por el procedimiento habitual.
## 5. Gasto y decisión de compra
“¿En qué herramientas, anuncios o servicios pagaste para este trabajo en los últimos tres meses? ¿Qué esperabas obtener y qué obtuviste?”
Repregunta: “¿Recordás el monto y la frecuencia? ¿Quién decidió y quién pagó? ¿Cancelaste alguno? ¿Por qué?” Si no paga por ninguno: “¿Cómo lo resolvés y cuánto tiempo te demanda?” No sugerir un precio todavía.
## 6. Prioridad y cambio de hábito
“De lo que vimos, ¿qué problema priorizarías hoy, si hay alguno? ¿Qué intentaste cambiar ya y qué pasó?”
Repregunta: “¿Qué funciona tan bien que no querrías cambiarlo? ¿Qué tendría que ocurrir para probar otra forma de resolver esa tarea?” Después pasar al experimento de la página 5.
## Variante para propietarios particulares
No aplicarles automáticamente el guion de CRM. Preguntar por su último inmueble ofrecido: dónde publicó, cómo gestionó consultas, qué actualizó, si contrató a un agente o pagó publicidad, cuánto y qué resultado obtuvo. Explorar quién decide contratar y qué información autoriza publicar. Analizar este segmento por separado.
## Repreguntas de reserva · Elegir solo si son relevantes
Precio: “Contame la última vez que ajustaste el precio: ¿qué información usaste y qué ocurrió?”
Oferta insuficiente: “Contame una consulta reciente que no pudiste atender con tu inventario. ¿Qué hiciste?”
No presuponer que necesitan más contactos: pueden necesitar mejores contactos, inventario, documentación o algo que KAZA no resuelve.
'''),
('Del comentario a una acción observable', '05 / PRUEBA OPCIONAL · 5 MINUTOS', '''
## Presentación neutral, solo después de escuchar
“Estamos explorando KAZA: una propuesta para consultar inmuebles por zona y revisar información para decidir cuáles contactar. Para agentes, estamos probando cómo organizar consultas y próximos pasos por propiedad. Lo que vamos a mostrar es un prototipo; algunas funciones y datos pueden ser de demostración.”
Mostrar únicamente el flujo relacionado con lo que contó la persona. No prometer inventario verificado, clientes, operaciones, aprobaciones financieras ni funciones aún no disponibles.
## A. Tarea para quien busca
“Con esta muestra, buscá una opción que considerarías contactar para tu necesidad. Decime qué harías después y qué información te falta.”
Dar hasta 3 minutos sin indicar dónde tocar. Registrar si completa la tarea sin ayuda, qué opción elige, dudas, bloqueos y tiempo. Separar errores de interfaz de falta de información o de oferta adecuada.
Después: “¿Qué parte te ayudó y qué parte resolvés mejor con tu método actual?” Si está buscando activamente, ofrecer una prueba posterior con criterios reales y contacto voluntario. No contar aceptar un mensaje como uso recurrente.
## B. Tarea para el agente
“Con este caso ficticio, registrá una consulta de esta propiedad y dejá claro cuál sería el siguiente paso.”
Registrar ayuda requerida, tiempo y objeciones. Después: “¿Esto encaja en tu trabajo o te agrega una tarea? ¿Qué tendrías que dejar de hacer para incorporarlo?”
## C. Compromiso para comprobar oferta
Solo si pueden ejecutar el piloto: “Estamos organizando una prueba de 7 días con 3 propiedades que tengas permiso de publicar. Requiere confirmar precio y disponibilidad al inicio y al cierre. No garantizamos consultas. ¿Te interesa participar bajo esas condiciones?”
Si acepta, acordar responsable, fecha de entrega y fecha de revisión. El compromiso queda pendiente hasta que entregue o confirme la información. Si rechaza: “¿Cuál es la razón principal?” Agradecer sin negociar su respuesta.
## D. Señal de pago, separada de la prueba gratuita
Después de explorar gasto y autoridad de compra, presentar una sola oferta comparable: “[Servicio concreto] durante [periodo], por Bs [precio definido por el equipo antes de las entrevistas], incluye [alcance]. ¿Qué paso seguiría en tu proceso para contratarlo? ¿Qué te lo impediría?”
Completar precio, alcance y condiciones antes de salir; no improvisarlos según la persona. Si solo existe un prototipo, aclarar que es una propuesta de piloto futuro y no cobrar por algo que no se puede entregar. Una reserva de interés o carta de intención no equivale a una venta.
## Escala de evidencia
Opinión favorable < contacto autorizado < reunión agendada < tarea completada < inventario entregado o uso repetido < pago por un servicio entregable. Registrar cada señal por su nombre; no sumarlas como si fueran equivalentes.
'''),
('Experimentos y decisiones del sábado', '06 / HIPÓTESIS → PRUEBA → DECISIÓN', '''
## Criterios propuestos para esta jornada
Acordarlos antes de entrevistar. Son umbrales internos para priorizar el siguiente experimento, no una certificación de negocio validado. Reportar números y denominadores; con muestras pequeñas, evitar porcentajes que aparenten precisión.
## H1 · Problema de búsqueda relevante
Prueba: 6 entrevistas a buscadores recientes del mismo segmento inicial, o resultados separados por operación.
Señal para continuar: al menos 4 de 6 relatan un caso reciente de la misma dificultad de información, con consecuencia y una acción para resolverla. Contar por separado lo espontáneo y lo sugerido por repregunta.
Si los problemas son distintos, o domina presupuesto/oferta, redefinir el problema. No asumir que un mapa resolverá todo lo mencionado.
## H2 · Dolor comercial del agente
Prueba: 6 entrevistas a agentes activos, explorando incidentes, procedimiento y recursos actuales.
Señal para continuar: al menos 4 de 6 describen la misma tarea problemática y 3 de 6 acreditan gasto actual o esfuerzo recurrente para resolverla. Registrar si la evidencia es relato, rango estimado o demostración voluntaria.
Si su proceso funciona bien, identificar otro segmento o dejar de priorizar CRM; no reinterpretar satisfacción como resistencia al cambio.
## H3 · Suministro y adopción
Prueba: invitar a los 6 agentes al mismo piloto de 3 propiedades / 7 días, solo si el equipo puede operarlo.
Señal inicial: 3 de 6 acuerdan responsable y fecha. Señal más fuerte: al menos 2 entregan inventario autorizado y confirman disponibilidad en la revisión del día 7. El sábado solo se puede reportar lo ya ocurrido; la retención queda pendiente.
## Monetización · Experimento separado
Entrevistar a quien decide el gasto. Ofrecer el mismo alcance y precio a 5 decisores elegibles; registrar cuántos aceptan una reunión de contratación, una propuesta escrita o un piloto pagado realmente entregable.
Meta exploratoria propuesta: 2 de 5 avanzan a un paso comercial con fecha. Esto permite seguir probando la oferta, pero no confirma ingresos. Sin oferta definida o decisor presente, anotar “pago no probado”.
## Prueba de concepto técnica (PoC)
Pregunta: “¿Podemos publicar 3 inmuebles autorizados, consultarlos por zona y reflejar un cambio de disponibilidad en mapa y detalle?”
Prueba controlada: registrar los 3 inmuebles; ejecutar 3 búsquedas de zona con resultado esperado; cambiar disponibilidad de uno y comprobar ambos lugares después de recargar. Criterio propuesto: 3 de 3 búsquedas correctas y cambio visible en menos de 60 segundos. Guardar tiempos y fallos.
Esta PoC prueba un flujo técnico. No prueba demanda, precisión legal de la información, integración bancaria ni disposición a pagar.
'''),
('Ficha de entrevista para imprimir', '07 / UNA FICHA POR PERSONA', '''
## Identificación mínima
Código: ____________________   Fecha: ______________   Entrevistador: ____________________
Segmento y rol: ____________________   Ciudad: ____________________
Operación: compra / alquiler / anticrético / otra: ____________________
Última experiencia: ____________________   Elegible para muestra principal: sí / no
Origen del contacto: ____________________   Relación con el equipo: ____________________
Notas autorizadas: sí / no   Grabación autorizada: sí / no / no solicitada
## Evidencia del caso
¿Qué intentaba hacer y cómo terminó? __________________________________________________
________________________________________________________________________________
Problema espontáneo o ausencia de problema: ___________________________________________
________________________________________________________________________________
Repregunta utilizada y respuesta obtenida: _________________________________________________
________________________________________________________________________________
Frecuencia y periodo recordado: ____________________   Total de casos recordados: __________
Consecuencia concreta: ______________________________________________________________
Tiempo / gasto / rango aproximado (o “no recuerda”): _______________________________________
Solución actual y qué funciona bien: ____________________________________________________
________________________________________________________________________________
Cita textual breve, sin nombres de terceros: _________________________________________________
________________________________________________________________________________
Tipo de evidencia: relato de caso / estimación / proceso observado / acción completada
## Negocio y prueba opcional
Quién usa: ____________________   Quién decide: ____________________   Quién paga: __________
Gasto actual y periodo: ____________________   Alternativa que reemplazaría: __________________
Tarea probada: ____________________   Resultado: sin ayuda / con ayuda / no completada / no probada
Oferta mostrada y precio, si corresponde: __________________________________________________
Compromiso exacto: ____________________   Responsable: ______________   Fecha: ____________
Estado: propuesto / aceptado / completado / rechazado   Motivo: _______________________________
## Interpretación del equipo · Completar después
Hipótesis: H1 / H2 / H3 / pago   Evidencia: apoya / contradice / insuficiente
Explicación alternativa: _________________________________________________________________
Próxima comprobación: _________________________________________________________________
Contacto futuro autorizado: sí / no. Guardar el dato de contacto por separado de esta ficha.
'''),
('Qué llevar y cómo contar lo aprendido', '08 / CHECKLIST Y SÍNTESIS', '''
## Antes de salir
[ ] Elegir un segmento y una operación inicial; escribir el supuesto prioritario.
[ ] Acordar criterios y denominadores de la página 6; ajustarlos ahora si no son viables.
[ ] Preparar guion, fichas, códigos de participantes y forma de registrar consentimiento.
[ ] Ensayar una entrevista entre el equipo para ajustar tiempo y neutralidad; no contarla como evidencia de mercado.
[ ] Tener prototipo probado, datos ficticios identificados y una alternativa en capturas si falla internet.
[ ] Definir quién podrá ejecutar el piloto, sus fechas y el tratamiento de datos.
[ ] Si se prueba pago, escribir alcance, precio, condiciones y limitaciones antes de ofrecerlo.
## Durante las entrevistas
[ ] No mostrar KAZA antes del relato de experiencia; no completar silencios con ejemplos.
[ ] Registrar lo que ya funciona, las negativas y los casos donde el problema no existe.
[ ] Pedir permiso antes de observar pantallas; no copiar datos personales de terceros.
[ ] Mantener iguales las tareas y ofertas para poder comparar resultados.
[ ] Registrar compromisos por separado de elogios y comentarios hipotéticos.
## Al terminar · 30 minutos de síntesis
Agrupar por segmento y operación. Elegir los dos patrones más repetidos y al menos una contradicción. Para cada patrón, anotar número de casos, consecuencia, alternativa actual y evidencia de acción.
Decidir una de tres cosas por hipótesis: continuar con una prueba concreta, reformular segmento/problema, o dejar de priorizarla por falta de evidencia. Si hay resultados mixtos, registrar qué falta saber.
## Plantilla para el pitch de validación
“Creíamos que [segmento] tenía [problema]. Entrevistamos a [n] personas elegibles, captadas en [canales]. [x de n] relataron [caso/patrón] y [y de n] ya lo resolvían con [alternativa o gasto]. También encontramos [contradicción].”
“Probamos [tarea/oferta] con [n]. Observamos [acciones completadas], mientras [pendientes] aún no ocurrieron. La PoC mostró [resultado técnico]. Decidimos [cambio] y lo siguiente será comprobar [incertidumbre] antes de [fecha].”
No llenar la plantilla con cifras inventadas. No decir “validamos el mercado” por una jornada de entrevistas ni presentar una aceptación verbal como ingreso.
## Cierre para leer al participante
“Gracias. Lo que nos contaste nos ayuda a decidir qué vale la pena resolver y qué deberíamos cambiar. ¿Hay algo importante que no te pregunté? [Si corresponde:] ¿Te parece que te contactemos una vez para coordinar la prueba acordada?”
## Material utilizado y alcance
Guion_Entrevistas_Validacion_KAZA.pdf: estructura de buscadores y agentes, canales, seguimiento y presentación posterior de KAZA.
KAZA_Guion_de_Validacion.pdf: experiencias concretas de comparación, confianza, decisiones comerciales y ficha de registro.
Imagen compartida: marco de preparación del prehackatón (hipótesis, experimentos, PoC y checklist). Los criterios, tamaños de muestra y pilotos de esta versión son propuestas para el equipo, no requisitos atribuidos al programa.
''')]
pdfmetrics.registerFont(TTFont('Kaza','C:/Windows/Fonts/arial.ttf'))
pdfmetrics.registerFont(TTFont('KazaBold','C:/Windows/Fonts/arialbd.ttf'))
styles=getSampleStyleSheet()
styles.add(ParagraphStyle(name='BodyK',fontName='Kaza',fontSize=9.5,leading=12.5,spaceAfter=5,textColor=colors.HexColor('#233846')))
styles.add(ParagraphStyle(name='HeadK',fontName='KazaBold',fontSize=11,leading=14,spaceBefore=6,spaceAfter=4,textColor=colors.HexColor('#087F83')))
styles.add(ParagraphStyle(name='TitleK',fontName='KazaBold',fontSize=22,leading=26,spaceAfter=13,textColor=colors.HexColor('#132F3D')))
styles.add(ParagraphStyle(name='LabelK',fontName='KazaBold',fontSize=9,leading=12,spaceAfter=9,textColor=colors.HexColor('#087F83')))
def footer(c,doc):
 c.setStrokeColor(colors.HexColor('#C8DEDF'));c.line(42,40,553,40)
 c.setFont('Kaza',8);c.setFillColor(colors.HexColor('#506773'))
 c.drawString(42,27,'KAZA | Validación de negocio | Guía de campo')
 c.drawRightString(553,27,str(doc.page))
story=[]
md=['# KAZA - Guion de validación mejorado\n']
for i,(title,label,body) in enumerate(pages):
 if i:story.append(PageBreak())
 story.extend([Paragraph(escape(label),styles['LabelK']),Paragraph(escape(title),styles['TitleK'])])
 md.extend(['\n## '+title+'\n',body])
 for line in body.strip().splitlines():
  if line.startswith('# '): continue
  if line.startswith('## '):story.append(Paragraph(escape(line[3:]),styles['HeadK']))
  else:story.append(Paragraph(escape(line),styles['BodyK']))
SimpleDocTemplate(str(OUT/'KAZA_Guion_Validacion_Mejorado.pdf'),pagesize=(595.28,841.89),rightMargin=42,leftMargin=42,topMargin=36,bottomMargin=52,title='KAZA - Guion de validación para el prehackatón',author='Equipo KAZA').build(story,onFirstPage=footer,onLaterPages=footer)
(OUT/'KAZA_Guion_Validacion_Mejorado.md').write_text('\n'.join(md),encoding='utf-8')
from pypdf import PdfReader
r=PdfReader(OUT/'KAZA_Guion_Validacion_Mejorado.pdf')
print('Páginas:',len(r.pages))
for i,p in enumerate(r.pages): print(i+1,len(p.extract_text()),p.extract_text().splitlines()[2:4])

