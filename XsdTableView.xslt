<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://www.w3.org/1999/xhtml">

<xsl:output media-type="text/html" method="html" encoding="utf-8" omit-xml-declaration="yes"  indent="yes" version="1.0"
            doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
            doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"/>
    <!--Current schema namespace-->
    <xsl:variable name="rootNamespace" select="/xs:schema/@targetNamespace"/>
    <!--Current schema namespace prefix-->
    <xsl:variable name="rootPrefix" select="name(//namespace::*[. = $rootNamespace])"/>
    <!--XSD prefix (usually used with xs: or xsd: preffixes)-->
    <xsl:variable name="xsdPrefix" select="name(//namespace::*[. = 'http://www.w3.org/2001/XMLSchema'])"/>

	<xsl:template match="/"><xsl:apply-templates select="/xs:schema"/></xsl:template>

	<xsl:template match="xs:schema">
        <!--Print only the first annotation in schema-->
		<xsl:if test="./xs:annotation">
            <h1><xsl:apply-templates select="./xs:annotation[position() = 1]" mode="Doc"/></h1>
        </xsl:if>
        <xsl:if test="$rootNamespace != ''">
            <p>Schema namespace: <span class="elementName"><xsl:value-of select="$rootNamespace"/></span></p>
        </xsl:if>
        <xsl:if test="$rootPrefix != ''">
            <p>Schema namespace prefix: <span class="elementName"><xsl:value-of select="$rootPrefix"/></span></p>
        </xsl:if>
        <xsl:if test="count(./@version) > 0">
            <p>Schema version: <span class="elementName"><xsl:value-of select="./@version"/></span></p>
        </xsl:if>
        <xsl:if test="count(./xs:import) > 0">
            <p>Imported namespaces:</p>
            <xsl:apply-templates select="./xs:import"/>
        </xsl:if>
        <!--Processing root elements declared in schema-->
		<xsl:apply-templates select="xs:element" mode="root"/>
        <!--Processing complex types declared in schema-->
<!--
        <xsl:variable name="internalComplexTypes" select="./xs:complexType[./@name != substring-after($rootElements/@type, ':')]"/>
        <xsl:if test="count($internalComplexTypes) > 0">
            <h4>Локальные сложные типы</h4>
            <xsl:apply-templates select="$internalComplexTypes" mode="InternalComplexType">
                <xsl:sort select="$internalComplexTypes/@name"/>
            </xsl:apply-templates>
        </xsl:if>
-->
	</xsl:template>

    <!--Imported namespaces description for the head-->
    <xsl:template match="xs:import">
        <xsl:variable name="namespace" select="@namespace"/>
        <span class="elementName"><xsl:value-of select="name(//namespace::*[. = $namespace])"/>: <xsl:value-of select="$namespace"/></span>
    </xsl:template>

	<!--Global elements description-->
	<xsl:template match="xs:element" mode="root">
		<h2>
            <xsl:if test="@type">
                <xsl:call-template name="TypeDescription"><xsl:with-param name="fullName" select="@type"/></xsl:call-template><br/>
            </xsl:if>
            <span class="elementName"><xsl:value-of select="@name"/></span>
        </h2>
		<table class="items" id="rootElement_{position()}">
			<tr>
				<!--Class AutoExpanded used in JS to determine cells to put colspan="..." in-->
				<th class="AutoExpanded">Entity</th>
				<th>Entity description</th>
				<th>Type</th>
				<th>Type description</th>
				<th>Cardinality</th>
			</tr>
			<xsl:apply-templates select="."/>
		</table>
	</xsl:template>

	<!--Описание простого или сложного типа-->
    <xsl:template name="TypeDescription">
        <!--Параметр, в котором передаётся полное имя типа (префикс:имя)-->
        <xsl:param name="fullName"/>
        <!--Локальная переменная: пространство имён схемы, зависит от контекста. Может быть для внешних схем. -->
        <xsl:variable name="schemaNamespace" select="/xs:schema/@targetNamespace"/>
        <!--Локальная переменная: префикс элементов схемы, зависит от контекста. Может быть для внешних схем. -->
        <xsl:variable name="schemaPrefix" select="name(//namespace::*[. = $schemaNamespace])"/>
        <xsl:variable name="prefix" select="substring-before($fullName, ':')"/>
        <xsl:variable name="name">
            <xsl:choose>
                <xsl:when test="contains($fullName, ':')"><xsl:value-of select="substring-after($fullName, ':')"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$fullName"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="$name = '' or ($prefix = $xsdPrefix and count(.//xs:element) = 0)">Простой тип XML Schema</xsl:when>
            <xsl:when test="$prefix = '' or $prefix = $schemaPrefix">
                <!--Тип объявлен внутри схемы либо в include схемах (другие XSD, но с тем же namespace)-->
                <!--Все схемы, которые include в данную (другие XSD, но с тем же namespace)-->
                <xsl:variable name="includedSchemas" select="document(/xs:schema/xs:include/@schemaLocation)"/>
                <!--Все схемы, которые рекурсивно include в схемы, которые include в данную (другие XSD, но с тем же namespace)-->
                <xsl:variable name="includedSchemasRecurse" select="document($includedSchemas/xs:schema/xs:include/@schemaLocation)"/>
                <xsl:variable
                        name="currNamespType"
                        select="/xs:schema/xs:complexType[@name = $name] | /xs:schema/xs:simpleType[@name = $name] |
                        $includedSchemas/xs:schema/xs:complexType[@name = $name] | $includedSchemas/xs:schema/xs:simpleType[@name = $name]|
                        $includedSchemasRecurse/xs:schema/xs:complexType[@name = $name]|
                        $includedSchemasRecurse/xs:schema/xs:simpleType[@name = $name]"/>
                <xsl:choose>
                    <!--Проверяем наличие типа в текущей схеме (текущей, в зависимости от контекста,
                    может быть как основная, так и импортируемая схема - если тип импортируемой схемы сам расширяет тип)-->
                    <xsl:when test="count($currNamespType) = 1">
                        <xsl:apply-templates select="$currNamespType/xs:annotation" mode="Doc"/>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="alert">Описание типа "<xsl:value-of select="$fullName"/>" в текущем namespace не найдено!</span>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!--Тип объявлен в одной из импортируемых схем. Определяем URI типа по его префиксу.-->
                <xsl:variable name="namespaceURI" select="namespace::*[name() = $prefix]"/>
                <!--Путь к файлу берём из параметра schemaLocation соответствующего URI элемента xs:import.-->
                <xsl:variable name="file" select="/xs:schema/xs:import[@namespace = $namespaceURI]/@schemaLocation"/>
                <!--Пытаемся загрузить внешний документ, используя путь к файлу.-->
                <xsl:variable name="externalSchemaDocument" select="document($file)"/>
                <xsl:choose>
                    <!--Проверяем, найден ли файл внешней схемы-->
                    <xsl:when test="$externalSchemaDocument">
                        <xsl:variable
                                name="externalType"
                                select="$externalSchemaDocument/xs:schema/xs:complexType[@name = $name]|$externalSchemaDocument/xs:schema/xs:simpleType[@name = $name]"/>
                        <xsl:choose>
                            <!--Проверяем наличие типа в импортируемой схеме-->
                            <xsl:when test="count($externalType) = 1">
                                <xsl:apply-templates select="$externalType/xs:annotation" mode="Doc"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <span class="alert">Тип "<xsl:value-of select="$fullName"/>" в файле "<xsl:value-of select="$file"/>" не найден!</span>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <span class="alert">Файл "<xsl:value-of select="$file"/>" не найден! Ошибка поиска описания типа "<xsl:value-of select="$fullName"/>".</span>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

	<!--Аннтотация к типу, элементу или схеме-->
	<xsl:template match="xs:annotation" mode="Doc">
        <!--На случай, если в текущем контексте есть несколько элементов xs:annotation-->
        <xsl:if test="position() != 1"><br/></xsl:if>
		<xsl:for-each select="xs:documentation">
			<xsl:value-of select="."/>
		</xsl:for-each>
		<xsl:for-each select="xs:appinfo">
			<xsl:value-of select="."/>
		</xsl:for-each>
	</xsl:template>

	<!--Элемент, описываемый схемой-->
	<xsl:template match="xs:element">
		<xsl:param name="level" select="0"/>
        <xsl:param name="prefix"/>
        <xsl:param name="parents"/>
        <xsl:param name="doNotProcessChildren" select="'No'"/>
        <!--Cardinality глобальных элементов передаются в параметрах minOcc и maxOcc.
        Если элемент не является глобальным, эти параметры переданы не будут,
        в таком случае, их значения заполнятся значеинями соответствующих атрибутов в определении элемента-->
        <xsl:param name="minOcc" select="@minOccurs"/>
        <xsl:param name="maxOcc" select="@maxOccurs"/>
        <xsl:variable name="ref" select="@ref"/>
        <xsl:choose>
            <xsl:when test="count($ref) = 0">
                <tr>
                    <xsl:call-template name="BlankCells"><xsl:with-param name="count" select="$level - 1"/></xsl:call-template>
                    <xsl:call-template name="Counter"><xsl:with-param name="level" select="$level"/></xsl:call-template>
                    <!--JavaScript код будет выставлять нужное значение colspan у ячеек с class="*AutoExpanded*"-->
                    <td class="elementName AutoExpanded">
                        <!--Если префикс пространства имён был передан в параметре, выводим его.-->
                        <xsl:if test="$prefix and $prefix != $rootPrefix"><xsl:value-of select="$prefix"/>:</xsl:if>
                        <xsl:value-of select="@name"/>
                    </td>
                    <td><xsl:apply-templates select="./xs:annotation" mode="Doc"/></td>
                    <td class="elementName"><xsl:call-template name="typeColumn"/></td>
                    <td>
                        <xsl:variable name="type"
                                      select="@type | ./xs:simpleType/xs:restriction/@base | ./xs:complexType/xs:simpleContent/xs:extension/@base"/>
                        <xsl:if test="$type != ''">
                            <xsl:call-template name="TypeDescription"><xsl:with-param name="fullName" select="$type"/></xsl:call-template>
                        </xsl:if>
                    </td>
                    <xsl:call-template name="Cardinality">
                        <xsl:with-param name="minOcc" select="$minOcc"/>
                        <xsl:with-param name="maxOcc" select="$maxOcc"/>
                    </xsl:call-template>
                </tr>
                <xsl:if test="$doNotProcessChildren != 'Yes'">
                    <xsl:variable name="childLevel" select="$level + 1"/>
                    <xsl:choose>
                        <!--Слишком большой уровень вложенности типов-->
                        <xsl:when test="$childLevel > 20">
                            <tr>
                                <xsl:call-template name="BlankCells">
                                    <xsl:with-param name="count" select="$level"/>
                                </xsl:call-template>
                                <td class="alert AutoExpanded">Уровень вложенности типов более 20 не поддерживается!</td>
                            </tr>
                        </xsl:when>
                        <xsl:when test="@type">
                            <!--Если тип элемента задан в параметре type. Обрабатываем вложенные элементы из этого типа.
                             Если же в данном элементе задано расширение какого-либо типа, оно будет обработано в шаблоне для xs:extension.-->
                            <xsl:call-template name="ComplexType">
                                <xsl:with-param name="fullName" select="@type"/>
                                <xsl:with-param name="level" select="$childLevel"/>
                                <xsl:with-param name="parents" select="$parents"/>
                                <xsl:with-param name="doNotProcessChildren">No</xsl:with-param>
                            </xsl:call-template>
                        </xsl:when>
                        <xsl:otherwise>
                            <!--Применяем шаблоны по умолчанию ко всем дочерним элементам.
                            Т.о., добавляем в таблицу элементы из расширяемых типов (extension), из sequence, choice или all-->
                            <xsl:apply-templates>
                                <xsl:with-param name="level" select="$childLevel"/>
                                <xsl:with-param name="prefix" select="$prefix"/>
                                <xsl:with-param name="parents" select="$parents"/>
                            </xsl:apply-templates>
                        </xsl:otherwise>
                    </xsl:choose>
                </xsl:if>
            </xsl:when>
            <xsl:otherwise>
                <!--Текущий элемент является ссылкой на глобальный элемент. То есть, имеет атрибут @ref-->
                <xsl:variable name="includedSchemas" select="document(/xs:schema/xs:include/@schemaLocation)"/>
                <!--Все схемы, которые рекурсивно include в схемы, которые include в данную (другие XSD, но с тем же namespace)-->
                <xsl:variable name="includedSchemasRecurse" select="document($includedSchemas/xs:schema/xs:include/@schemaLocation)"/>
                <!--Ищем определение глобального элемента в текущей схеме, а также в included схемах-->
                <xsl:variable name="refWoPreffix" select="substring-after($ref, ':')"/>
                <xsl:apply-templates
                        select="/xs:schema/xs:element[@name = $refWoPreffix] | $includedSchemas/xs:schema/xs:element[@name = $refWoPreffix] |
                        $includedSchemasRecurse/xs:schema/xs:element[@name = $refWoPreffix]">
                    <xsl:with-param name="level" select="$level"/>
                    <xsl:with-param name="prefix" select="$prefix"/>
                    <xsl:with-param name="parents" select="$parents"/>
                    <xsl:with-param name="doNotProcessChildren" select="$doNotProcessChildren"/>
                    <xsl:with-param name="minOcc" select="$minOcc"/>
                    <xsl:with-param name="maxOcc" select="$maxOcc"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--Ячейка таблицы, содержащая счётчик-->
    <xsl:template name="Counter">
        <xsl:param name="level"/>
        <xsl:if test="$level > 0">
            <!--В эту ячейку JavaScript после загрузки страницы добавит счётчик - номер текущего элемента.
            Здесь, в преобразовании, записываем в ячейку уровень вложенности текущего элемента.-->
            <td class="counter"><xsl:value-of select="$level"/></td>
        </xsl:if>
    </xsl:template>

    <!--Множественность элемента-->
    <xsl:template name="Cardinality">
        <xsl:param name="minOcc"/>
        <xsl:param name="maxOcc"/>
        <td class="cardinality">
            <xsl:variable name="min">
                <xsl:choose>
                    <xsl:when test="$minOcc"><xsl:value-of select="$minOcc"/></xsl:when>
                    <xsl:otherwise>1</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:variable name="max">
                <xsl:choose>
                    <xsl:when test="$maxOcc = 'unbounded'">n</xsl:when>
                    <xsl:when test="$maxOcc"><xsl:value-of select="$maxOcc"/></xsl:when>
                    <xsl:otherwise>1</xsl:otherwise>
                </xsl:choose>
            </xsl:variable>
            <xsl:choose>
                <xsl:when test="$min = $max">[<xsl:value-of select="$min"/>]</xsl:when>
                <xsl:otherwise>[<xsl:value-of select="$min"/>..<xsl:value-of select="$max"/>]</xsl:otherwise>
            </xsl:choose>
        </td>
    </xsl:template>

	<!--Описание атрибута-->
	<xsl:template match="xs:attribute">
        <xsl:param name="level" select="0"/>
        <!--Cardinality глобальных атрибутов передаётся в параметре use.
        Если атрибут не является глобальным, данный параметр передан не будет,
        в таком случае, его значение возьмётся из @use определения атрибута-->
        <xsl:param name="use" select="@use"/>

        <xsl:variable name="ref" select="@ref"/>
        <xsl:choose>
            <xsl:when test="count($ref) = 0">
                <tr>
                    <xsl:call-template name="BlankCells"><xsl:with-param name="count" select="$level - 1"/></xsl:call-template>
                    <xsl:call-template name="Counter"><xsl:with-param name="level" select="$level"/></xsl:call-template>
                    <td class="AutoExpanded attributeName">@<xsl:value-of select="@name"/></td>
                    <td><xsl:apply-templates select="./xs:annotation" mode="Doc"/></td>
                    <td><xsl:call-template name="typeColumn"/></td>
                    <td>
                        <xsl:call-template name="TypeDescription">
                            <xsl:with-param name="fullName" select="@type"/>
                        </xsl:call-template>
                    </td>
                    <td class="cardinality">
                        <xsl:choose>
                            <xsl:when test="$use = 'required'">[1]</xsl:when>
                            <xsl:when test="$use = 'prohibited'">[0]</xsl:when>
                            <xsl:otherwise>[0..1]</xsl:otherwise>
                        </xsl:choose>
                    </td>
                </tr>
            </xsl:when>
            <xsl:otherwise>
                <!--Текущий атрибут является ссылкой на глобальный атрибут. То есть, имеет атрибут @ref-->
                <xsl:variable name="includedSchemas" select="document(/xs:schema/xs:include/@schemaLocation)"/>
                <!--Все схемы, которые рекурсивно include в схемы, которые include в данную (другие XSD, но с тем же namespace)-->
                <xsl:variable name="includedSchemasRecurse" select="document($includedSchemas/xs:schema/xs:include/@schemaLocation)"/>
                <!--Ищем определение глобального атрибута в текущей схеме, а также в included схемах-->
                <xsl:apply-templates
                        select="/xs:schema/xs:attribute[@name = $ref] | $includedSchemas/xs:schema/xs:attribute[@name = $ref] |
                        $includedSchemasRecurse/xs:schema/xs:attribute[@name = $ref]">
                    <xsl:with-param name="level" select="$level"/>
                    <xsl:with-param name="use" select="$use"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
	</xsl:template>

    <!--Значение колонки "Тип". То есть, тип элемента или атрибута-->
    <xsl:template name="typeColumn">
        <xsl:variable name="extendedType"
                      select="./xs:complexType/xs:complexContent/xs:extension/@base | ./xs:complexType/xs:simpleContent/xs:extension/@base"/>
        <xsl:variable name="type" select="@type | $extendedType"/>
        <xsl:variable name="typePrefix" select="substring-before($type, ':')"/>
        <!--Получаем название типа элемента или атрибута без префикса-->
        <xsl:variable name="typeName">
            <xsl:choose>
                <xsl:when test="contains($type, ':')"><xsl:value-of select="substring-after($type, ':')"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$type"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:if test="$typePrefix != '' and $typePrefix != $rootPrefix"><xsl:value-of select="$typePrefix"/>:</xsl:if>
        <xsl:value-of select="$typeName"/>
        <xsl:if test="count($extendedType) > 0"><br/><i> (тип расширен)</i></xsl:if>
        <xsl:if test="@fixed"><br/>Fixed: "<xsl:value-of select="@fixed"/>"</xsl:if>
        <xsl:apply-templates select="xs:simpleType/xs:restriction" mode="simpleTypeRestriction"/>
    </xsl:template>

    <!--Ограничение простого типа из пространства имён XML Schema-->
    <xsl:template match="xs:restriction" mode="simpleTypeRestriction">
        <xsl:value-of select="@base"/>
        <xsl:if test="count(./xs:length) > 0">
            <nobr>
                <xsl:text> [</xsl:text>
                <xsl:value-of select="./xs:length/@value"/>
                <xsl:text>] </xsl:text>
            </nobr>
        </xsl:if>
        <xsl:if test="count(./xs:minLength | ./xs:maxLength) > 0">
            <nobr>
                <xsl:text> [</xsl:text>
                <xsl:apply-templates select="./xs:minLength | ./xs:maxLength" mode="simpleTypeRestriction">
                    <xsl:sort order="descending" select="name()"/>
                </xsl:apply-templates>
                <xsl:text>]</xsl:text>
            </nobr>
        </xsl:if>
        <xsl:if test="count(./xs:pattern) > 0">
            <br/>RegEx: <xsl:apply-templates select="./xs:pattern" mode="comaSeparatedPattern"/>
        </xsl:if>
        <xsl:if test="count(./xs:enumeration) > 0">
            <br/>Варианты: <xsl:apply-templates select="./xs:enumeration" mode="comaSeparatedPattern"/>
        </xsl:if>
    </xsl:template>

    <!--Разделяет элементы запятой и пробелом-->
    <xsl:template mode="comaSeparatedPattern" match="*">
        <xsl:if test="position() > 1"><xsl:text>, </xsl:text></xsl:if>
        <xsl:text>"</xsl:text><xsl:value-of select="@value"/><xsl:text>"</xsl:text>
    </xsl:template>

    <!--Минимальная длина строки-->
    <xsl:template match="xs:minLength" mode="simpleTypeRestriction">
        <xsl:text>min: </xsl:text>
        <xsl:value-of select="@value"/>
    </xsl:template>

    <!--Максимальная длина строки простого типа-->
    <xsl:template match="xs:maxLength" mode="simpleTypeRestriction">
        <xsl:if test="position() > 1"><xsl:text>, </xsl:text></xsl:if>
        <xsl:text>max: </xsl:text>
        <xsl:value-of select="@value"/>
    </xsl:template>

	<!--Добавляем элементы из сложных типов, которые могут быть использованы напрямую, параметром type элемента, так и в xs:extension-->
	<xsl:template name="ComplexType">
		<xsl:param name="fullName"/>
        <xsl:param name="level"/>
        <xsl:param name="parents" select="''"/>
        <xsl:param name="doNotProcessChildren"/>
        <!--Локальная переменная: пространство имён схемы, зависит от контекста. Может быть для внешних схем. -->
        <xsl:variable name="schemaNamespace" select="/xs:schema/@targetNamespace"/>
        <!--Локальная переменная: префикс элементов схемы, зависит от контекста. Может быть для внешних схем. -->
        <xsl:variable name="schemaPrefix" select="name(//namespace::*[. = $schemaNamespace])"/>
        <xsl:variable name="prefix" select="substring-before($fullName, ':')"/>
        <xsl:variable name="name">
            <xsl:choose>
                <xsl:when test="contains($fullName, ':')"><xsl:value-of select="substring-after($fullName, ':')"/></xsl:when>
                <xsl:otherwise><xsl:value-of select="$fullName"/></xsl:otherwise>
            </xsl:choose>
        </xsl:variable>
        <xsl:variable name="childParents" select="concat($parents, $fullName, ';')"/>
        <xsl:choose>
            <!--Cycle detected: the type of the element is the same as of one of its ancestors-->
            <xsl:when test="contains($parents, concat($fullName, ';'))">
                <tr>
                    <xsl:call-template name="BlankCells"><xsl:with-param name="count" select="$level"/></xsl:call-template>
                    <td class="AutoExpanded">Тип <b><xsl:value-of select="$fullName"/></b> образует цикл</td>
                </tr>
            </xsl:when>

            <!--Do nothing with XML Schema simple types-->
            <xsl:when test="($prefix = '' or $prefix = $xsdPrefix) and ($name = 'string' or $name = 'decimal' or $name = 'base64Binary' or $name = 'float' or $name = 'short'
             or $name = 'integer' or $name = 'positiveInteger' or $name = 'boolean' or $name = 'date' or $name = 'time' or $name = 'dateTime' or $name = 'long' or $name = 'int' or  $name = 'unsignedLong' or $name = 'unsignedByte')"/>

            <xsl:when test="$prefix = '' or $prefix = $schemaPrefix">
                <!--The type is declared within current schema-->
                <!--All schemas included in current (another XSDs with the same namespace)-->
                <xsl:variable name="includedSchemas" select="document(/xs:schema/xs:include/@schemaLocation)"/>
                <!--All schemas recursively included in the schemas that are included in currnt(another XSDs with the same namespace)-->
                <xsl:variable name="includedSchemasRecurse" select="document($includedSchemas/xs:schema/xs:include/@schemaLocation)"/>
                <xsl:variable
                        name="currNamespType"
                        select="/xs:schema/xs:complexType[@name = $name] | /xs:schema/xs:simpleType[@name = $name] |
                        $includedSchemas/xs:schema/xs:complexType[@name = $name] | $includedSchemas/xs:schema/xs:simpleType[@name = $name] |
                        $includedSchemasRecurse/xs:schema/xs:complexType[@name = $name] | $includedSchemasRecurse/xs:schema/xs:simpleType[@name = $name]"/>

                <xsl:choose>
                    <!--Checking the existence of the type in current namespace-->
                    <xsl:when test="count($currNamespType) = 1">
                        <xsl:apply-templates select="$currNamespType">
                            <xsl:with-param name="level" select="$level"/>
                            <xsl:with-param name="prefix" select="$prefix"/>
                            <xsl:with-param name="parents" select="$childParents"/>
                            <xsl:with-param name="doNotProcessChildren" select="$doNotProcessChildren"/>
                        </xsl:apply-templates>
                    </xsl:when>
                    <xsl:otherwise>
                        <tr>
                            <xsl:call-template name="BlankCells"><xsl:with-param name="count" select="$level"/></xsl:call-template>
                            <td class="alert AutoExpanded">Type "<xsl:value-of select="$fullName"/>" is not found in current namespace</td>
                        </tr>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:when>
            <xsl:otherwise>
                <!--Тип объявлен в одной из импортируемых схем-->
                <xsl:variable name="namespaceURI" select="namespace::*[name() = $prefix]"/>
                <xsl:variable name="file" select="/xs:schema/xs:import[@namespace = $namespaceURI]/@schemaLocation"/>
                <xsl:variable name="externalSchemaDocument" select="document($file)"/>
                <xsl:choose>
                    <!--Проверяем, найден ли файл внешней схемы-->
                    <xsl:when test="$externalSchemaDocument">
                        <xsl:variable
                                name="externalType"
                                select="$externalSchemaDocument/xs:schema/xs:complexType[@name = $name]|$externalSchemaDocument/xs:schema/xs:simpleType[@name = $name]"/>
                        <xsl:choose>
                            <!--Проверяем наличие типа в импортируемой схеме-->
                            <xsl:when test="count($externalType) = 1">
                                <xsl:apply-templates select="$externalType">
                                    <xsl:with-param name="prefix" select="$prefix"/>
                                    <xsl:with-param name="level" select="$level"/>
                                    <xsl:with-param name="parents" select="$childParents"/>
                                    <xsl:with-param name="doNotProcessChildren" select="$doNotProcessChildren"/>
                                </xsl:apply-templates>
                            </xsl:when>
                            <xsl:otherwise>
                                <tr>
                                    <xsl:call-template name="BlankCells"><xsl:with-param name="count" select="$level"/></xsl:call-template>
                                    <td class="alert AutoExpanded">Тип "<xsl:value-of select="$fullName"/>" в файле "<xsl:value-of select="$file"/>" не найден!</td>
                                </tr>
                            </xsl:otherwise>
                        </xsl:choose>
                    </xsl:when>
                    <xsl:otherwise>
                        <tr>
                            <xsl:call-template name="BlankCells">
                                <xsl:with-param name="count" select="$level"/>
                            </xsl:call-template>
                            <td class="alert AutoExpanded">
                                File "<xsl:value-of select="$file"/>" not found. Error while searching for the "<xsl:value-of select="$fullName"/> type"
                            </td>
                        </tr>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:otherwise>
        </xsl:choose>
	</xsl:template>

	<!--Ничего не делаем с annotation, т.к. их обработали отдельно в шаблоне mode="Doc",
	который отрабатывает лишний раз, если нет этого шаблона по умолчанию-->
	<xsl:template match="xs:annotation"/>

	<!--Для этих элементов просто вызываем шаблоны, подходящие к дочерним, с передачей всех параметров-->
	<xsl:template match="xs:sequence | xs:complexContent | xs:simpleContent | xs:complexType">
		<xsl:param name="level"/>
		<xsl:param name="prefix"/>
        <xsl:param name="parents"/>
        <xsl:param name="doNotProcessChildren"/>
        <!--Сначала нужно вывести описание атрибутов-->
		<xsl:apply-templates select="xs:attribute | xs:attributeGroup">
			<xsl:with-param name="level" select="$level"/>
    		<xsl:with-param name="prefix" select="$prefix"/>
		</xsl:apply-templates>
        <!--Нужно вывести описание элементов (не атрибутов)-->
        <xsl:apply-templates select="*[local-name() != 'attribute' and local-name() != 'attributeGroup']">
            <xsl:with-param name="level" select="$level"/>
            <xsl:with-param name="prefix" select="$prefix"/>
            <xsl:with-param name="parents" select="$parents"/>
            <xsl:with-param name="doNotProcessChildren" select="$doNotProcessChildren"/>
        </xsl:apply-templates>
	</xsl:template>

    <!--Группа атрибутов. Бывает только глобальная, то есть, объявляется в корне схемы-->
    <xsl:template match="xs:attributeGroup">
        <xsl:param name="level"/>
        <xsl:param name="prefix"/>

        <xsl:variable name="ref" select="@ref"/>
        <xsl:choose>
            <xsl:when test="count($ref) = 0">
                <!--Параметр @ref отсутстует. Значит, это объявление группы атрибутов в корне схемы-->
                <xsl:apply-templates select="xs:attribute">
                    <xsl:with-param name="level" select="$level"/>
                    <xsl:with-param name="prefix" select="$prefix"/>
                </xsl:apply-templates>
                </xsl:when>
            <xsl:otherwise>
                <!--Присутствует параметр @ref. Значит, это ссылка на группу атрибутов. Нужно найти её и применить этот же шаблон-->
                <xsl:variable name="includedSchemas" select="document(/xs:schema/xs:include/@schemaLocation)"/>
                <!--Все схемы, которые рекурсивно include в схемы, которые include в данную (другие XSD, но с тем же namespace)-->
                <xsl:variable name="includedSchemasRecurse" select="document($includedSchemas/xs:schema/xs:include/@schemaLocation)"/>
                <xsl:apply-templates
                        select="/xs:schema/xs:attributeGroup[@name = $ref] | $includedSchemas/xs:schema/xs:attributeGroup[@name = $ref] |
                        $includedSchemasRecurse/xs:schema/xs:attributeGroup[@name = $ref]">
                    <xsl:with-param name="level" select="$level"/>
                    <xsl:with-param name="prefix" select="$prefix"/>
                </xsl:apply-templates>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!--xs:choice и xs:all обрабатываем отдельно от xs:sequence. Вложенные элементы делаем дочерними к choice или all-->
    <xsl:template match="xs:choice | xs:all">
        <xsl:param name="level"/>
        <xsl:param name="prefix"/>
        <xsl:param name="parents"/>
        <xsl:param name="doNotProcessChildren"/>

        <tr>
            <xsl:call-template name="BlankCells"><xsl:with-param name="count" select="$level - 1"/></xsl:call-template>
            <xsl:call-template name="Counter"><xsl:with-param name="level" select="$level"/></xsl:call-template>
            <td class="elementGroup AutoExpanded">
                <xsl:for-each select="xs:annotation"><xsl:apply-templates/><br/></xsl:for-each>
                <xsl:choose>
                    <xsl:when test="local-name(.) = 'choice'"><b>choice</b>: должен присутствовать <b>один</b> из перечисленных ниже элементов</xsl:when>
                    <xsl:otherwise><b>all</b>: должны присутствовать <b>все</b> перечисленные ниже элементы</xsl:otherwise>
                </xsl:choose>
            </td>
            <xsl:call-template name="Cardinality">
                <xsl:with-param name="minOcc" select="@minOccurs"/>
                <xsl:with-param name="maxOcc" select="@maxOccurs"/>
            </xsl:call-template>
        </tr>

        <xsl:apply-templates select="*">
            <xsl:with-param name="level" select="$level + 1"/>
            <xsl:with-param name="prefix" select="$prefix"/>
            <xsl:with-param name="parents" select="$parents"/>
            <xsl:with-param name="doNotProcessChildren" select="$doNotProcessChildren"/>
        </xsl:apply-templates>
    </xsl:template>

	<!--Расширение сложного типа-->
	<xsl:template match="xs:extension">
		<xsl:param name="level"/>
        <xsl:param name="prefix" select="''"/>
        <xsl:param name="parents"/>
        <xsl:param name="doNotProcessChildren"/>
		<!--Сначала выводим элементы, объявленные в сложном типе-->
        <xsl:call-template name="ComplexType">
            <xsl:with-param name="fullName" select="@base"/>
            <xsl:with-param name="level" select="$level"/>
            <xsl:with-param name="parents" select="$parents"/>
            <xsl:with-param name="doNotProcessChildren" select="$doNotProcessChildren"/>
        </xsl:call-template>
        <!--Затем выводим элементы, объявленные в расширении-->
		<xsl:apply-templates>
			<xsl:with-param name="level" select="$level"/>
            <xsl:with-param name="parents" select="$parents"/>
            <xsl:with-param name="prefix" select="$prefix"/>
            <xsl:with-param name="doNotProcessChildren" select="$doNotProcessChildren"/>
		</xsl:apply-templates>
	</xsl:template>

	<!--Шаблон рекурсивно вызывает себя count количество раз. Каждый раз шаблон дописывает пустую ячейку. -->
	<xsl:template name="BlankCells">
		<xsl:param name="count" select="1"/>
		<xsl:if test="$count &gt; 0">
			<td class="blank"/>
			<xsl:call-template name="BlankCells">
				<xsl:with-param name="count" select="$count - 1"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>

    <!--Описания сложных типов-->
<!--
TODO: Реализовать в общем виде
    <xsl:template match="xs:complexType" mode="InternalComplexType">
        <xsl:variable name="fullName"><xsl:value-of select="$rootSchemaPrefix"/>:<xsl:value-of select="@name"/></xsl:variable>
        <h5><xsl:value-of select="@name"/></h5>
        <p class="bold">Определение:</p>
        <p class="elementName">
            <xsl:call-template name="TypeDescription">
                <xsl:with-param name="fullName" select="$fullName"/>
            </xsl:call-template>
        </p>

        <xsl:variable name="baseTypeExtension" select="./xs:complexContent/xs:extension"/>
        <xsl:if test="count($baseTypeExtension) > 0">
            <p class="bold">Наследует свойства типа:</p>
            <p class="elementName"><xsl:value-of select="$baseTypeExtension/@base"/></p>
        </xsl:if>
        <p class="bold" style="margin-bottom: 6pt;">Дочерние элементы:</p>
        <xsl:if test="count(descendant::xs:element) > 0">
            <table class="items">
                <tr>
                    <th>Имя</th>
                    <th>Определение</th>
                    <th>Тип</th>
                    <th>Описание типа</th>
                    <th>Мн.</th>
                </tr>
                <xsl:apply-templates select=".">
                    <xsl:with-param name="doNotProcessChildren">Yes</xsl:with-param>
                </xsl:apply-templates>
            </table>
        </xsl:if>

        &lt;!&ndash;Родительские элементы, содежращие в качестве непосредственных дочерних элементы с описываемым типом&ndash;&gt;
        <xsl:variable
                name="parentElements"
                select="//xs:element[substring-after(@type, ':') = //xs:complexType[count(descendant::xs:element[@type = $fullName]) > 0]/@name]"/>

        <xsl:if test="count($parentElements) > 0">
            <p class="bold" style="margin-bottom: 6pt; margin-top: 6pt;">Родительские элементы:</p>
            <table class="items">
                <tr>
                    <th>Имя</th>
                    <th>Определение</th>
                    <th>Имя роли</th>
                    <th>Описание роли</th>
                    <th>Мн.</th>
                </tr>
                <xsl:apply-templates select="$parentElements">
                    <xsl:with-param name="doNotProcessChildren">Yes</xsl:with-param>
                </xsl:apply-templates>
            </table>
        </xsl:if>
    </xsl:template>-->
</xsl:stylesheet>
