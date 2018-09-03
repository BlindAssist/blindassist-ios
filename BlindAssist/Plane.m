//
//  Plane.m
//  BlindAssist
//
//  Created by Giovanni Terlingen on 03/09/2018.
//  Copyright © 2018 Giovanni Terlingen. All rights reserved.
//

#import "Plane.h"
#import <math.h>

@implementation Plane

- (id)init:(ARPlaneAnchor*)anchor in:(ARSCNView*)sceneView {
    // Create a mesh to visualize the estimated shape of the plane.
    ARSCNPlaneGeometry *meshGeometry = [ARSCNPlaneGeometry planeGeometryWithDevice:sceneView.device];
    [meshGeometry updateFromPlaneGeometry:anchor.geometry];
    self.meshNode = [SCNNode nodeWithGeometry:meshGeometry];
    
    // Create a node to visualize the plane's bounding rectangle.
    SCNPlane *extentPlane = [SCNPlane planeWithWidth:anchor.extent.x height:anchor.extent.z];
    self.extentNode = [SCNNode nodeWithGeometry:extentPlane];
    self.extentNode.simdPosition = anchor.center;
    
    // `SCNPlane` is vertically oriented in its local coordinate space, so
    // rotate it to match the orientation of `ARPlaneAnchor`.
    SCNVector3 eulerAngles = self.extentNode.eulerAngles;
    eulerAngles.x = -M_PI / 2;
    self.extentNode.eulerAngles = eulerAngles;
    
    self = [super init];
    
    // Add the plane extent and plane geometry as child nodes so they appear in the scene.
    [super addChildNode:self.meshNode];
    [super addChildNode:self.extentNode];
    
    return self;
}

-(void)setupMeshVisualStyle {
    // Make the plane visualization semitransparent to clearly show real-world placement.
    self.meshNode.opacity = 0.4f;
    
    SCNMaterial *material = self.meshNode.geometry.firstMaterial;
    material.diffuse.contents = [UIColor colorNamed:@"appYellow"];
    material.blendMode = SKBlendModeAdd;
}

-(void)setupExtentVisualStyle {
    // Make the extent visualization semitransparent to clearly show real-world placement.
    self.extentNode.opacity = 0.6f;
    
    SCNMaterial *material = self.extentNode.geometry.firstMaterial;
    material.diffuse.contents = [UIColor colorNamed:@"planeColor"];
    material.blendMode = SKBlendModeAdd;
    
}

@end
