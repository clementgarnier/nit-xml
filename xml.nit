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

        fun to_xml(indent: Bool): String do return format_xml(indent, 0)
        
        private fun format_xml(indent: Bool, depth: Int): String is abstract

        private fun indent_xml(depth: Int, xml_string: String): String do
                assert depth >= 0

                var xml: String = ""
                for i in [0..depth - 1] do xml += "\t"
                xml += xml_string
                return xml
        end

end

interface XPathable

        fun xpath_query(query: String): Array[XMLElement] is abstract
 
end

# An XPath query result, also query-able
class XPathResult
        super Array[XMLElement]
        super XPathable

        redef fun xpath_query(query: String): XPathResult do
                var results = new XPathResult

                for e in self do results.add_all(e.xpath_query(query))
                
                return results
        end
end

# An XML document representation
class XMLDocument
        super XMLisable
        super XPathable

        var version: Float
        var root: nullable XMLElement writable = null

        init(version: Float) do
                assert version == 1.0 or version == 1.1

                self.version = version
        end

        redef fun format_xml(indent: Bool, depth: Int): String do
                var xml = "<?xml version=\"{self.version}\"?>"
                if self.root != null then xml += "\n" + self.root.to_xml(indent)
                return xml
        end

        fun save(file: String, indent: Bool) do
		        var out = new OFStream.open(file)
		        out.write(self.to_xml(indent))
		        out.close
	    end

        redef fun xpath_query(query: String): XPathResult do
                assert not query.is_empty

                var results = new XPathResult

                if query[0] != '/' then
                        print("Cannot execute relative XPath query on a document, try on a node instead.")
                        return results
                end
                
                if self.root == null then return results

                var root = self.root

                if query == "/" and root != null then
                        results.add(root)
                else
                        var slices = query.split_with('/')

                        # //foo
                        if slices.length == 3 and slices[1].is_empty then
                                results.add_all(self.root.search_all_by_name(slices[2], true))
                        else
                                # /foo
                                if slices.length == 2 and self.root.value == slices[1] and root != null then
                                        results.add(root)
                                # /foo(/bar)+
                                else if slices.length > 2 then
                                        slices.remove_at(0)
                                        
                                        if slices[0] == self.root.value then
                                                slices.remove_at(0)

                                                results.add_all(self.root.nested_search_all_by_name(slices))
                                        end
                                end
                        end
                end

                return results
        end

        # Look for all elements called "name" in the document, recursively or not
        private fun search_all_by_name(name: String, recursive: Bool): Array[XMLNode] do
                return self.root.search_all_by_name(name, recursive)
        end

end

# An XML attribute representation
class XMLAttribute
        var name: String
        var value: String

        # Avoid duplicate attributes
        redef fun ==(a) do return a isa XMLAttribute and a.name == self.name

        # TODO faire hashcode
end

# An abstract XML node representation
abstract class XMLNode
        super XMLisable
        
        var value: String
end

# An XML standard element representation
class XMLElement
        super XMLNode
        super XPathable

        var children: Array[XMLNode] = new Array[XMLNode]
        var attributes: ArraySet[XMLAttribute] = new ArraySet[XMLAttribute]

        init(value: String) do 
                assert value != ""

                self.value = value
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

        fun has_children: Bool do
                if self.children.length > 0 then return true
                return false
        end

        redef fun format_xml(indent: Bool, depth: Int): String do
                if not indent then depth = 0

                var opening_tag = "<{self.value}"
                for a in attributes do opening_tag += " {a.name}=\"{a.value}\""

                # No children: close tag and return
                if children.is_empty then
                        opening_tag += "/>"
                        return self.indent_xml(depth, opening_tag)
                end

                opening_tag += ">"

                var xml = self.indent_xml(depth, opening_tag)
                
                # Write children
                for c in children do xml += "\n" + c.format_xml(indent, depth + 1)

                xml += "\n"

                # Close tag
                var close_tag = "</{self.value}>"
                xml += self.indent_xml(depth, close_tag)
                
                return xml
        end

        # Look for all children elements called "name", recursively or not
        private fun search_all_by_name(name: String, recursive: Bool): Array[XMLElement] do
                var results = new Array[XMLElement]
                
                for c in children do
                        if c isa XMLElement then
                                if c.value == name then results.add(c)
                                if recursive and c.has_children then results.add_all(c.search_all_by_name(name, recursive))
                        end
                end

                return results
        end
       
        # Look for an ordered succession of children
        private fun nested_search_all_by_name(names: Array[String]): Array[XMLElement] do
                var results = new Array[XMLElement]
                
                var parent_results: Array[XMLElement] = [self]

                for depth in [0..names.length[ do
                        results.clear
                        
                        for node in parent_results do results.add_all(node.search_all_by_name(names[depth], false))

                        parent_results.clear
                        parent_results.add_all(results)
                end

                return results
        end

        redef fun xpath_query(query: String): XPathResult do
                assert not query.is_empty

                var results = new XPathResult

                if query[0] == '/' then
                        print("Cannot execute absolute XPath query on an element, try on the document instead.")
                        return results
                end

                var slices = query.split_with('/')

                # foo
                if slices.length == 1 then
                        results.add_all(self.search_all_by_name(slices[0], false))
                # foo(/bar)+
                else if slices.length > 1 then
                        results.add_all(self.nested_search_all_by_name(slices))
                end

                return results
        end
end

abstract class XMLSpecialNode
        super XMLNode

        init(value: String) do
                assert value != ""

                self.value = value
        end
end

# An XML comment representation
class XMLComment
        super XMLSpecialNode

        init(value: String) do
                assert value != ""

                self.value = value
        end

        redef fun format_xml(indent: Bool, depth: Int): String do
                if not indent then depth = 0

                return self.indent_xml(depth, "<!-- {self.value} -->")
        end
end

# An XML text representation
class XMLText
        super XMLSpecialNode

        init(value: String) do
                assert value != ""

                self.value = value
        end

        redef fun format_xml(indent: Bool, depth: Int): String do
                if not indent then depth = 0

                return self.indent_xml(depth, self.value)
        end
end

# An XML Processing Instruction (PI) representation
class XMLPI
        super XMLSpecialNode

        var target: String = ""

        init(value: String) do
                assert value != ""

                self.value = value
        end

        fun set_target(target: String) do
                assert target != ""

                self.target = target
        end
        
        fun with_target(target: String): XMLPI do
                self.set_target(target)

                return self
        end

        redef fun format_xml(indent: Bool, depth: Int): String do
                if not indent then depth = 0

                return self.indent_xml(depth, "<?{self.target} {self.value}?>")
        end
end

# An XML CDATA representation
class XMLCDATA
        super XMLSpecialNode

        init(value: String) do
                assert value != ""

                self.value = value
        end

        redef fun format_xml(indent: Bool, depth: Int): String do
                if not indent then depth = 0

                return self.indent_xml(depth, "<![CDATA[{self.value}]]>")
        end
end

