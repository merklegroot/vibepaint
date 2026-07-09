import 'package:image/image.dart' as img;
import 'package:vibepaint/utils/image_adjustments.dart';

img.Image ditheringEffect(
  img.Image source, {
  required int colorLevels,
  required img.DitherKernel kernel,
  bool serpentine = false,
}) {
  final copy = cloneImage(source);
  final colors = colorLevels.clamp(2, 256);

  if (kernel == img.DitherKernel.none) {
    return img.quantize(copy, numberOfColors: colors);
  }

  return img.ditherImage(
    copy,
    quantizer: img.NeuralQuantizer(copy, numberOfColors: colors),
    kernel: kernel,
    serpentine: serpentine,
  );
}

String ditherKernelLabel(img.DitherKernel kernel) {
  return switch (kernel) {
    img.DitherKernel.none => 'None',
    img.DitherKernel.falseFloydSteinberg => 'False Floyd-Steinberg',
    img.DitherKernel.floydSteinberg => 'Floyd-Steinberg',
    img.DitherKernel.stucki => 'Stucki',
    img.DitherKernel.atkinson => 'Atkinson',
  };
}

const ditherKernelOptions = <img.DitherKernel>[
  img.DitherKernel.floydSteinberg,
  img.DitherKernel.falseFloydSteinberg,
  img.DitherKernel.stucki,
  img.DitherKernel.atkinson,
  img.DitherKernel.none,
];
