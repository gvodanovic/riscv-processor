# Toma de Notas

## Observaciones del estudio
- **Parámetros limitados**: La investigación solo se centró en analizar el tamaño de la caché, su asociatividad y los predictores de saltos, sin considerar otros componentes arquitectónicos relevantes.
- **Optimización parcial con ML**: Se utilizó aprendizaje automático para optimizar únicamente el IPC (instrucciones por ciclo) y el consumo de recursos (LUTs), dejando de lado otras métricas importantes.
- **Benchmarks desactualizados**: Los conjuntos de pruebas utilizados carecen de aplicaciones modernas como aprendizaje automático (ML), criptografía o procesamiento de grafos.
- **Falta de análisis de seguridad**: No se evaluó el impacto en vulnerabilidades como ataques side-channel (Spectre, Meltdown) al modificar predictores o cachés.
- **Enfoque limitado en consumo energético**: El estudio no priorizó la eficiencia energética como criterio fundamental en la optimización.
- **Plataforma de validación obsoleta**: La FPGA Kintex-7 operando a 50 MHz utilizada para validación es un modelo antiguo que no refleja las frecuencias reales de operación del CVA6 en implementaciones actuales.

## Benchmarks utilizados en el estudio IEEE
- **Micro-benchmarks**: Suite de validación RISC-V ([enlace](https://github.com/darchr/riscv-validation))
- **MiBench**: Conjunto de benchmarks para sistemas embebidos ([enlace](https://github.com/darchr/riscv-validation))