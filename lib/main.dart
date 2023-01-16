import 'dart:math';

import 'package:arkit_plugin/arkit_plugin.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart' as color;
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'mam-ar-game',
      home: MyHomePage(title: 'mam-ar-game'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late ARKitController arkitController;
  ARKitPlane? plane;
  ARKitNode? node;
  String? anchorId;
  String _selectedShape = '';
  final String _chars =
      'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
  final Random _rnd = Random();

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  String getRandomString(int length) => String.fromCharCodes(Iterable.generate(
      length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('mam-ar-game')),
      body: ARKitSceneView(
        showFeaturePoints: true,
        enableTapRecognizer: true,
        planeDetection: ARPlaneDetection.horizontalAndVertical,
        onARKitViewCreated: onARKitViewCreated,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Select a shape"),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: <Widget>[
                      GestureDetector(
                        child: const Text("Sphere"),
                        onTap: () {
                          _selectedShape = 'sphere';
                          Navigator.of(context).pop();
                        },
                      ),
                      const Padding(padding: EdgeInsets.all(8.0)),
                      GestureDetector(
                        child: const Text("Cube"),
                        onTap: () {
                          _selectedShape = 'cube';
                          Navigator.of(context).pop();
                        },
                      ),
                      const Padding(padding: EdgeInsets.all(8.0)),
                      GestureDetector(
                        child: const Text("Cylinder"),
                        onTap: () {
                          _selectedShape = 'cylinder';
                          Navigator.of(context).pop();
                        },
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ));

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    this.arkitController.onAddNodeForAnchor = _handleAddAnchor;
    this.arkitController.onUpdateNodeForAnchor = _handleUpdateAnchor;
    this.arkitController.onNodeTap = (nodes) => onNodeTapHandler(nodes);
    this.arkitController.onARTap = (ar) {
      final point = ar.firstWhere(
        (o) => o.type == ARKitHitTestResultType.featurePoint,
      );
      _onARTapHandler(point);
    };
  }

  void onNodeTapHandler(List<String> nodesList) {
    final name = nodesList.first;
    if (name.contains('shape')) {
      arkitController.update(name, materials: [
        ARKitMaterial(
          lightingModelName: ARKitLightingModel.physicallyBased,
          diffuse: ARKitMaterialProperty.color(
            Colors.yellow[600]!,
          ),
          metalness: ARKitMaterialProperty.value(1),
          roughness: ARKitMaterialProperty.value(0),
        )
      ]);
    }
  }

  void _handleAddAnchor(ARKitAnchor anchor) {
    if (!(anchor is ARKitPlaneAnchor)) {
      return;
    }
    _addPlane(arkitController, anchor);
  }

  void _handleUpdateAnchor(ARKitAnchor anchor) {
    if (anchor.identifier != anchorId || anchor is! ARKitPlaneAnchor) {
      return;
    }
    node?.position = vector.Vector3(anchor.center.x, 0, anchor.center.z);
    plane?.width.value = anchor.extent.x;
    plane?.height.value = anchor.extent.z;
  }

  void _addPlane(ARKitController controller, ARKitPlaneAnchor anchor) {
    anchorId = anchor.identifier;
    plane = ARKitPlane(
      width: anchor.extent.x,
      height: anchor.extent.z,
      materials: [ARKitMaterial(colorBufferWriteMask: ARKitColorMask.none)],
    );

    node = ARKitNode(
      geometry: plane,
      renderingOrder: -1,
      position: vector.Vector3(anchor.center.x, 0, anchor.center.z),
      rotation: vector.Vector4(1, 0, 0, -math.pi / 2),
    );
    controller.add(node!, parentNodeName: anchor.nodeName);
  }

  void _onARTapHandler(ARKitTestResult point) {
    final rand = getRandomString(15);
    final position = vector.Vector3(
      point.worldTransform.getColumn(3).x,
      point.worldTransform.getColumn(3).y,
      point.worldTransform.getColumn(3).z,
    );
    if (_selectedShape == 'sphere') {
      final material =
          ARKitMaterial(diffuse: ARKitMaterialProperty.color(color.Colors.red));
      final sphere = ARKitSphere(
        radius: 0.01,
        materials: [material],
      );
      final node =
          ARKitNode(name: 'shape$rand', geometry: sphere, position: position);
      arkitController.add(node);
    } else if (_selectedShape == 'cube') {
      final material = ARKitMaterial(
          diffuse: ARKitMaterialProperty.color(color.Colors.blue));
      final cube = ARKitBox(
        width: 0.01,
        height: 0.01,
        length: 0.01,
        materials: [material],
      );
      final node =
          ARKitNode(name: 'shape$rand', geometry: cube, position: position);
      arkitController.add(node);
    } else if (_selectedShape == 'cylinder') {
      final material = ARKitMaterial(
          diffuse: ARKitMaterialProperty.color(color.Colors.green));
      final cube = ARKitCylinder(
        radius: 0.01,
        height: 0.01,
        materials: [material],
      );
      final node =
          ARKitNode(name: 'shape$rand', geometry: cube, position: position);
      arkitController.add(node);
    }
    _selectedShape = '';
  }
}
