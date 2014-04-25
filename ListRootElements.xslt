<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema">
	<xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:template match="/">
		<html>
			<head>
				<title>Root elements of the schema</title>
			</head>
			<style type="text/css">
				table {border: none; border-collapse: collapse}
				th, td {border: 1px solid black}
				th {background: #E6E6E6}
			</style>
			<body>
				<table>
					<tbody>
						<tr>
							<th>Root element</th>
							<th>Annotation</th>
						</tr>
						<xsl:apply-templates select="/xs:schema/xs:element"/>
					</tbody>
				</table>
			</body>
		</html>
	</xsl:template>
	<xsl:template match="xs:element">
		<tr>
			<td><xsl:value-of select="@name"/></td>
			<td><xsl:apply-templates select="xs:annotation"/></td>
		</tr>
	</xsl:template>
</xsl:stylesheet>
