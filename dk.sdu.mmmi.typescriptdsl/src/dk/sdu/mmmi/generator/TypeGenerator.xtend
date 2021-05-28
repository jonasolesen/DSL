package dk.sdu.mmmi.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2
import dk.sdu.mmmi.typescriptdsl.Table

class TypeGenerator implements FileGenerator {

	override generate(Resource resource, IFileSystemAccess2 fsa) {
		val tables = resource.allContents.filter(Table).toList
		val generators = newArrayList(
			new UtilityTypeGenerator,
			new TableTypeGenerator,
			new DelegateGenerator,
			new TableDataGenerator,
			new ConstraintGenerator
		)

		fsa.generateFile('index.ts', generators.map[generate(tables)].join('\n'))
	}
}
