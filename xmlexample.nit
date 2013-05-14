import xml

var document = new XMLDocument(1.0)

document.root = (new XMLElement("mesh")).
                        with_attributes(new XMLAttribute("name", "mesh_root"),
                                        new XMLAttribute("name", "duplicate")).
                        with_children(new XMLComment("here is a mesh node"),
                                      new XMLText("some text"),
                                      new XMLCDATA("someothertext"),
                                      new XMLText("some more text"),
                                      (new XMLElement("node")).
                                                with_attributes(new XMLAttribute("attr1", "value1"),
                                                                new XMLAttribute("attr2", "value2")),
                                      ((new XMLElement("node")).
                                                with_attributes(new XMLAttribute("attr1", "value2"))).
                                                with_children(new XMLElement("innernode")),
                                      (new XMLPI("somedata")).
                                                with_target("include"))

print document.to_xml(true)

document.save("document.xml", false)
