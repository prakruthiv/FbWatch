// Scott Hale (Oxford Internet Institute), modified by Lukas Brückner (Karlsruhe Institute of Technology)
// Requires sigma.js and jquery to be loaded
// based on parseGexf from Mathieu Jacomy @ Sciences Po Médialab & WebAtlas
sigma.publicPrototype.parseJson = function(jsonPath, callback) {
    var sigmaInstance = this;
    var edgeId = 0;
    jQuery.getJSON(jsonPath, function(data) {
        for (var node_id in data.nodes) {
            var theNode = data.nodes[node_id];

            if (theNode.x == undefined) {
                theNode.x = Math.random();
            }
            if (theNode.y == undefined) {
                theNode.y = Math.random();
            }

            sigmaInstance.addNode(theNode.id, theNode);
        }

        for (j = 0; j < data.edges.length; j++) {
            var edgeNode = data.edges[j];
            if (edgeNode.weight != undefined) {
                edgeNode.size = edgeNode.weight
            }

            sigmaInstance.addEdge(edgeId++, edgeNode['source'], edgeNode['target'], edgeNode);
        }

        if (callback) {
            callback.call(this);//Trigger the data ready function
        }
    });//end jquery getJSON function
};//end sigma.parseJson function