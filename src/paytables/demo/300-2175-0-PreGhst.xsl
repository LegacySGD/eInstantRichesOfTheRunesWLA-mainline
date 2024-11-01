<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var mainData = getOutcomeData(scenario, 0);
						var bonusData = getOutcomeData(scenario, 1);
						var multiData = getOutcomeData(scenario, 2);
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');
						var convertedPrizeValues = (prizeValues.substring(1)).split('|');

						// Output Main Game table.
						const multis = [10,5,4,3,2];
						var r = [];
						var bonusSymbolText = '';
						var gameSymb = '';
						var isBonusSymb = false;
						var isMatchSymb = false;
						var isMultiSymb = false;
						var mainBonusCount = 0;
						var mainLastBonus = -1;
						var mainLastMatch = -1;
						var mainLastMulti = -1;
						var mainMatchCount = 0;
						var mainMultiCount = 0;
						var mainSymbolText = '';
						var outcomeText = '';
						var prizeStr = '';
						var prizeText  = '';
						var secondSymbolText = '';

						r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed;overflow-x:scroll">');
						r.push('<tr class="tablehead">');
						r.push('<td colspan="5">');
						r.push(getTranslationByName("mainGame", translations));
 						r.push('</td>');
						r.push('</tr>');
						r.push('<tr class="tablehead">');
						r.push('<td>');
						r.push(getTranslationByName("turn", translations));
 						r.push('</td>');
						r.push('<td>');
						r.push(getTranslationByName("mainSymbol", translations));
 						r.push('</td>');
						r.push('<td>');
						r.push(getTranslationByName("secondSymbol", translations));
 						r.push('</td>');
						r.push('<td>');
						r.push(getTranslationByName("outcome", translations));
 						r.push('</td>');
						r.push('<td>');
						r.push(getTranslationByName("prize", translations));
 						r.push('</td>');
						r.push('</tr>');

						for (var turnIndex = 0; turnIndex < mainData.length; turnIndex++)
						{
							gameSymb = mainData[turnIndex];

							isMatchSymb = (gameSymb[0] == 'Y');
							isBonusSymb = (gameSymb[1] >= '1' && gameSymb[1] <= '4');
							isMultiSymb = (gameSymb[1] >= '5' && gameSymb[1] <= '8');

							mainMatchCount += (isMatchSymb) ? 1 : 0;
							mainBonusCount += (isBonusSymb) ? 1 : 0;
							mainMultiCount += (isMultiSymb) ? 1 : 0;

							mainLastMatch = (isMatchSymb) ? turnIndex : mainLastMatch;
							mainLastBonus = (isBonusSymb) ? turnIndex : mainLastBonus;
							mainLastMulti = (isMultiSymb) ? turnIndex : mainLastMulti;
						}

						prizeStr = (mainMatchCount >= 4) ? 'M' + mainMatchCount.toString() : '';

						for (var turnIndex = 0; turnIndex < mainData.length; turnIndex++)
						{
							gameSymb = mainData[turnIndex];

							mainSymbolText   = getTranslationByName("mainSymb" + gameSymb[0], translations);
							secondSymbolText = (gameSymb[1] != '0') ? getTranslationByName("mainSymb" + gameSymb[1], translations) : '';							
							outcomeText      = (mainMatchCount >= 4 && turnIndex == mainLastMatch) ? getTranslationByName("matched", translations) + ' ' + mainMatchCount.toString() : '';
							outcomeText     += (mainBonusCount == 4 && turnIndex == mainLastBonus) ? ((outcomeText != '') ? ', ' : '') + getTranslationByName("bonusGame", translations) : '';
							outcomeText     += (mainMultiCount == 4 && turnIndex == mainLastMulti) ? ((outcomeText != '') ? ', ' : '') + getTranslationByName("multiGame", translations) : '';
							prizeText        = (mainMatchCount >= 4 && turnIndex == mainLastMatch) ? convertedPrizeValues[getPrizeNameIndex(prizeNames,prizeStr)] : '';

							r.push('<tr>');
							r.push('<td class="tablebody">' + (turnIndex+1).toString() + '</td>');
							r.push('<td class="tablebody">' + mainSymbolText + '</td>');
							r.push('<td class="tablebody">' + secondSymbolText + '</td>');
							r.push('<td class="tablebody">' + outcomeText + '</td>');
							r.push('<td class="tablebody">' + prizeText + '</td>');
							r.push('</tr>');
						}

						r.push('<tr><td class="tablebody">&nbsp;</td></tr>');
						r.push('</table>');

						if (mainBonusCount == 4)
						{
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed;overflow-x:scroll">');
							r.push('<tr class="tablehead">');
							r.push('<td colspan="4">');
							r.push(getTranslationByName("bonusGame", translations));
							r.push('</td>');
							r.push('</tr>');
							r.push('<tr class="tablehead">');
							r.push('<td>');
							r.push(getTranslationByName("turn", translations));
							r.push('</td>');
							r.push('<td>');
							r.push(getTranslationByName("bonusSymbol", translations));
							r.push('</td>');
							r.push('<td>');
							r.push(getTranslationByName("outcome", translations));
							r.push('</td>');
							r.push('<td>');
							r.push(getTranslationByName("prize", translations));
							r.push('</td>');
							r.push('</tr>');

							mainLastMulti = -1;

							for (var turnIndex = 0; turnIndex < bonusData.length; turnIndex++)
							{
								gameSymb = bonusData[turnIndex];

								isMultiSymb = (gameSymb[0] >= '5' && gameSymb[0] <= '8');

								mainMultiCount += (isMultiSymb) ? 1 : 0;
								
								mainLastMulti = (isMultiSymb) ? turnIndex : mainLastMulti;
							}

							for (var turnIndex = 0; turnIndex < bonusData.length; turnIndex++)
							{
								gameSymb = bonusData[turnIndex];

								bonusSymbolText = (gameSymb[0] == 'W') ? getTranslationByName("bonusPrize", translations) : getTranslationByName("mainSymb" + gameSymb[0], translations);							
								outcomeText     = (mainMultiCount == 4 && turnIndex == mainLastMulti) ? getTranslationByName("multiGame", translations) : '';
								prizeText       = (gameSymb[0] == 'W') ? convertedPrizeValues[getPrizeNameIndex(prizeNames,gameSymb)] : '';

								r.push('<tr>');
								r.push('<td class="tablebody">' + (turnIndex+1).toString() + '</td>');
								r.push('<td class="tablebody">' + bonusSymbolText + '</td>');
								r.push('<td class="tablebody">' + outcomeText + '</td>');
								r.push('<td class="tablebody">' + prizeText + '</td>');
								r.push('</tr>');
							}

							r.push('<tr><td class="tablebody">&nbsp;</td></tr>');
							r.push('</table>');
						}

						if (mainMultiCount == 4)
						{
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed;overflow-x:scroll">');
							r.push('<tr class="tablehead">');
							r.push('<td colspan="1">');
							r.push(getTranslationByName("multiGame", translations));
							r.push('</td>');
							r.push('</tr>');
							r.push('<tr class="tablebody">');
							r.push('<td>' + getTranslationByName("multipliedBy", translations) + ' ' + multis[parseInt(multiData[1])-1] + '</td>');
							r.push('</tr>');
							r.push('<tr><td class="tablebody">&nbsp;</td></tr>');
							r.push('</table>');
						}

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 						{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 							r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 							r.push('</td>');
 						r.push('</tr>');
							}
						r.push('</table>');
							
						}
						
						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					function getOutcomeData(scenario, index)
					{
						var outcomeData = scenario.split("|");

						if (index == 0 || index == 1)
						{
							return outcomeData[index].split(",");
						}
						else if (index == 2)
						{
							return outcomeData[index];
						}
					}
					
					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "M11,M10,M9,M8,..." and "IW"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">

					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>
			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
