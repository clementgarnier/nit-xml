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

printn("document.xpath_query(\"/\") => ")
for n in document.xpath_query("/") do printn(n.to_xml(false))
print("")

printn("document.xpath_query(\"/mesh\") => ")
for n in document.xpath_query("/mesh") do printn(n.to_xml(false))
print("\n")

printn("document.xpath_query(\"/mesh/node\") => ")
for n in document.xpath_query("/mesh/node") do printn(n.to_xml(false))
print("\n")

printn("document.xpath_query(\"/mesh/node/innernode\") => ")
for n in document.xpath_query("/mesh/node/innernode") do printn(n.to_xml(false))
print("\n")

printn("document.xpath_query(\"//node\") => ")
for n in document.xpath_query("//node") do printn(n.to_xml(false))
print("\n")

printn("document.xpath_query(\"//innernode\") => ")
for n in document.xpath_query("//innernode") do printn(n.to_xml(false))
print("\n")

printn("document.root.xpath_query(\"node\") => ")
for n in document.root.xpath_query("node") do printn(n.to_xml(false))
print("\n")

printn("document.root.xpath_query(\"node/innernode\") => ")
for n in document.root.xpath_query("node/innernode") do printn(n.to_xml(false))
print("\n")

printn("document.root.xpath_query(\"node\").xpath_query(\"innernode\") => ")
for n in document.root.xpath_query("node").xpath_query("innernode") do printn(n.to_xml(false))
print("\n")
