from lxml import etree
from pathlib import Path
import pandas as pd


GML_NS = "http://www.opengis.net/gml/3.2"


def build_gml_id_map(xml_doc):
    """
    Build a dictionary:
        {line_number: gml:id}
    """
    gml_map = {}

    for elem in xml_doc.iter():
        gml_id = elem.get(f"{{{GML_NS}}}id")
        if gml_id:
            gml_map[elem.sourceline] = gml_id

    return gml_map


def find_gml_id(error_line, gml_map):
    """
    Find the nearest previous gml:id based on line number.
    """
    nearest_id = None

    for line in sorted(gml_map):
        if line <= error_line:
            nearest_id = gml_map[line]
        else:
            break

    return nearest_id


def get_xml_root_info(xml_file):
    try:
        doc = etree.parse(str(xml_file))
        root = doc.getroot()

        qname = etree.QName(root)

        return {
            "root_name": qname.localname,
            "root_namespace": qname.namespace
        }
    except etree.XMLSyntaxError as e:
        print("XML Syntax Error:")
        for error in e.error_log:
            print(f"Line {error.line}, Column {error.column}: {error.message}")
        return None


def get_xsd_target_namespace(xsd_file):
    doc = etree.parse(str(xsd_file))
    root = doc.getroot()

    return root.get("targetNamespace")


def validate_xsd(xml_file_path, xsd_file_path="xsd/aixm-5-1-20100201-xsd/xsd/message/AIXM_BasicMessage.xsd"):
    xml_file = Path(xml_file_path)
    xsd_file = Path(xsd_file_path)

    if not xml_file.exists():
        print(f"XML file not found: {xml_file}")
        return False

    if not xsd_file.exists():
        print(f"XSD file not found: {xsd_file}")
        return False

    xml_info = get_xml_root_info(xml_file)
    if xml_info is None:
        return False
    xsd_namespace = get_xsd_target_namespace(xsd_file)

    print("XML root element:", xml_info["root_name"])
    print("XML root namespace:", xml_info["root_namespace"])
    print("XSD target namespace:", xsd_namespace)

    if xml_info["root_namespace"] != xsd_namespace:
        print("\nNamespace mismatch!")
        print("Your XML namespace and XSD target namespace are different.")
        print("Use matching AIXM version XSD.")
        return False

    schema_doc = etree.parse(str(xsd_file))
    schema = etree.XMLSchema(schema_doc)

    try:
        xml_doc = etree.parse(str(xml_file))
    except etree.XMLSyntaxError as e:
        print("\nXML is not well formed.")
        for error in e.error_log:
            print(f"Line {error.line}, Column {error.column}: {error.message}")
        return False
    gml_map = build_gml_id_map(xml_doc) 
    is_valid = schema.validate(xml_doc)

    if is_valid:
        print("\nAIXM XML is valid.")
        return True

    print("\nAIXM XML is not valid.")
    errors = []
    for error in schema.error_log:
        gml_id = find_gml_id(error.line, gml_map)


        errors.append(
            {   
                "gml_ID":gml_id,
                "line_number": error.line,
                "column": error.column,
                "domain": error.domain_name,
                "type": error.type_name,
                "message": error.message
            }
        )


    # # Create dataframe
    # error_df = pd.DataFrame(
    #     errors
    # )

    # return {
    #     "status": bool(is_valid),

    #     "error_count": len(errors),

    #     "errors": error_df.to_dict(
    #         orient="records"
    #     )
    # }
    return {
        "status": bool(is_valid),
        "error_count": len(errors),
        "errors": errors
    }

# if __name__ == "__main__":
#     # xml_file = "./SampleXml/Area 1.xml"

#     # Use AIXM 5.1 XSD because your XML uses:
#     # http://www.aixm.aero/schema/5.1/message
#     # xsd_file = "aixm-5-1-20100201-xsd/xsd/message/AIXM_BasicMessage.xsd"

#     validate_xsd(xml_file, xsd_file)


