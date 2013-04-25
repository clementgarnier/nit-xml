# This file is part of NIT ( http://www.nitlanguage.org ).
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# XML output facilities
module xml

# Any xml-formatable data
interface XMLisable
        fun to_xml: String do return to_indented_xml(0)

        private fun to_indented_xml(depth: Int): String do return indent_xml(depth, self.format_xml(depth))

        private fun indent_xml(depth: Int, xml_string: String): String do
                assert depth >= 0

                var xml: String = ""
                for i in [0..depth - 1] do xml += "\t"
                xml += xml_string
                return xml
        end

        private fun format_xml(depth: Int): String is abstract
end

# An XML document representation
class XMLDocument
        super XMLisable

        var version: Float
        var root: nullable XMLElement writable = null

        init(version: Float) do
                assert version == 1.0 or version == 1.1

                self.version = version
        end

        redef fun format_xml(depth: Int): String do
                var xml = "<?xml version=\"{self.version}\"?>"
                if self.root != null then xml += "\n" + self.root.to_indented_xml(depth)
                return xml
        end
end

# An XML attribute of which value is of type E
class XMLAttribute
        var name: String
        var value: String

        redef fun ==(a) do return a isa XMLAttribute and a.name == self.name
end

# An abstract XML node representation
abstract class XMLNode
        super XMLisable
        
        var value: String
end

# An XML standard element representation
class XMLElement
        super XMLNode

        var children: Array[XMLNode]
        var attributes: ArraySet[XMLAttribute]

        init(value: String) do 
                self.value = value
                self.children = new Array[XMLNode]
                self.attributes = new ArraySet[XMLAttribute]
        end

        fun set_attributes(attributes: XMLAttribute...) do
                for a in attributes do self.attributes.add(a)
        end

        private fun set_attributes_array(attributes: Array[XMLAttribute]) do
                for a in attributes do self.attributes.add(a)
        end

        fun with_attributes(attributes: XMLAttribute...): XMLElement do
                self.set_attributes_array(attributes)

                return self
        end

        fun add_children(children: XMLNode...) do
                self.children.add_all(children)
        end

        private fun add_children_array(children: Array[XMLNode]) do
                self.children.add_all(children)
        end

        fun with_children(children: XMLNode...): XMLElement do
                self.add_children_array(children)

                return self
        end

        redef fun format_xml(depth: Int): String do
                var xml = "<{self.value}"
                for a in attributes do xml += " {a.name}=\"{a.value}\""
                if children.is_empty then return xml + "/>"

                xml += ">"
                
                for c in children do xml += "\n" + c.to_indented_xml(depth + 1)

                xml += "\n" + self.indent_xml(depth, "</{self.value}>")

                return xml
        end
end

abstract class XMLSpecialNode
        super XMLNode

        init(value: String) do
                self.value = value
        end
end

# An XML comment representation
class XMLComment
        super XMLSpecialNode

        init(value: String) do
                self.value = value
        end

        redef fun format_xml(depth: Int): String do
                return "<!-- {self.value} -->"
        end
end

# An XML text representation
class XMLText
        super XMLSpecialNode

        init(value: String) do
                self.value = value
        end

        redef fun format_xml(depth: Int): String do
                return self.value
        end
end

# An XML Processing Instruction (PI) representation
class XMLPI
        super XMLSpecialNode

        var target: String = ""

        init(value: String) do
                self.value = value
        end
        
        fun with_target(target: String): XMLPI do
                self.target = target

                return self
        end

        redef fun format_xml(depth: Int): String do
                return "<?{self.target} {self.value}?>"
        end
end

# An XML CDATA representation
class XMLCDATA
        super XMLSpecialNode

        init(value: String) do
                self.value = value
        end

        redef fun format_xml(depth: Int): String do
                return "<![CDATA[{self.value}]]>"
        end
end

