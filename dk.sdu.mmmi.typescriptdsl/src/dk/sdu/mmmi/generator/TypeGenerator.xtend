package dk.sdu.mmmi.generator

import dk.sdu.mmmi.typescriptdsl.Table
import dk.sdu.mmmi.typescriptdsl.TableFunction
import java.util.List
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2

class TypeGenerator implements FileGenerator {

	override generate(Resource resource, IFileSystemAccess2 fsa) {
		val tables = resource.allContents.filter(Table).toList
		val tableFunctions = resource.allContents.filter(TableFunction).toList

		fsa.generateFile('index.ts', newArrayList(
			tables.generateTables,
			tables.generateTableFunctions(tableFunctions)
		).join('\n'))
	}

	def generateTables(List<Table> tables) {
		newArrayList(
			new UtilityTypeGenerator,
			new TableTypeGenerator,
			new TableDataGenerator,
			new ConstraintGenerator
		).map[generate(tables)].join('\n')
	}

	def generateTableFunctions(List<Table> tables, List<TableFunction> tableFunctions) {
		val entries = tables.map[table | table -> tableFunctions.findFirst[it.table.name === table.name]]

		newArrayList(
			new DelegateGenerator,
			new FunctionGenerator
		).map[generate(entries)].join('\n')
	}
}
