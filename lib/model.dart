import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:pytorch_mobile/enums/dtype.dart';

const TORCHVISION_NORM_MEAN_RGB = [0.485, 0.456, 0.406];
const TORCHVISION_NORM_STD_RGB = [0.229, 0.224, 0.225];

class Model {
  static const MethodChannel _channel = const MethodChannel('pytorch_mobile');

  final int _index;

  Model(this._index);

  ///predicts abstract number input
  Future<List?> getPrediction(
      List<double> input, List<int> shape, DType dtype) async {
    final List? prediction = await _channel.invokeListMethod('predict', {
      "index": _index,
      "data": input,
      "shape": shape,
      "dtype": dtype.toString().split(".").last
    });
    return prediction;
  }

  ///predicts image and returns the supposed label belonging to it
  Future<List<String>> getImagePrediction(
      File image, int width, int height, String labelPath,
      {List<double> mean = TORCHVISION_NORM_MEAN_RGB,
        List<double> std = TORCHVISION_NORM_STD_RGB}) async {
    // Assert mean std
    assert(mean.length == 3, "mean should have size of 3");
    assert(std.length == 3, "std should have size of 3");

    print(labelPath);
    print("Apoorva");

    List<String> colorLabels = await _getLabels(labelPath);
    List<String> typeLabels = await _getLabels("assets/labels/type_labels.csv");
    List byteArray = image.readAsBytesSync();
    // final List? prediction = await _channel.invokeListMethod("predictImage", {
    //   "index": _index,
    //   "image": byteArray,
    //   "width": width,
    //   "height": height,
    //   "mean": mean,
    //   "std": std
    // });

    final List? prediction = await _channel.invokeListMethod("predictImage", {
      "index": _index,
      "image": byteArray,
      "width": width,
      "height": height,
      "mean": mean,
      "std": std
    });


    print("object");
    print(prediction);
    double maxScoreColor = double.negativeInfinity;
    double maxScoreType = double.negativeInfinity;

    int maxScoreIndexColor = -1;
    int maxScoreIndexType = -1;

    List<String> outputList=[];
    double confidentTypeDn=0.0;
    double confidentColorDn=0.0;

    for(int i=0; i< prediction![0].length; i++){
      if (prediction[0][i] > maxScoreColor) {
        maxScoreColor = prediction[0][i];
        maxScoreIndexColor = i;
        confidentColorDn=exp(confidentColorDn+prediction[0][i]);
      }
    }
    for(int i=0; i< prediction![1].length; i++){
      if (prediction[1][i] > maxScoreType) {
        maxScoreType = prediction[1][i];
        maxScoreIndexType = i;
        confidentTypeDn=exp(confidentTypeDn+prediction[1][i]);
      }
    }
    double confidentTypeNm = exp(prediction![1][maxScoreIndexType]);
    double confidentColorNm = exp(prediction![0][maxScoreIndexColor]);


    print("confidence");
    print(confidentTypeNm/confidentTypeDn);
    print(confidentColorNm/confidentColorDn);

    var confidenceType = ((confidentTypeNm/confidentTypeDn)*100).toStringAsFixed(2);
    var confidenceColor = ((confidentColorNm/confidentColorDn)*100).toStringAsFixed(2);

    outputList.add(colorLabels[maxScoreIndexColor]+'Accuracy: '+ confidenceColor);
    outputList.add(typeLabels[maxScoreIndexType] + 'Accuracy: '+ confidenceType);

    if(prediction![2][0]>5.0)
      return outputList;
    else return ['Invalid','Invalid'];
  }

  ///predicts image but returns the raw net output
  Future<List?> getImagePredictionList(File image, int width, int height,
      {List<double> mean = TORCHVISION_NORM_MEAN_RGB,
      List<double> std = TORCHVISION_NORM_STD_RGB}) async {
    // Assert mean std
    assert(mean.length == 3, "Mean should have size of 3");
    assert(std.length == 3, "STD should have size of 3");
    final List? prediction = await _channel.invokeListMethod("predictImage", {
      "index": _index,
      "image": image.readAsBytesSync(),
      "width": width,
      "height": height,
      "mean": mean,
      "std": std
    });
    return prediction;
  }

  //get labels in csv format
  Future<List<String>> _getLabels(String labelPath) async {
    String labelsData = await rootBundle.loadString(labelPath);
    return labelsData.split(",");
  }
}
