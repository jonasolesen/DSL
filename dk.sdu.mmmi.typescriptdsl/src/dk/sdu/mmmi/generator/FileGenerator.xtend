package dk.sdu.mmmi.generator

import dk.sdu.mmmi.typescriptdsl.Table
import dk.sdu.mmmi.typescriptdsl.TableFunction
import java.util.List
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess2

interface FileGenerator {
	def void generate(Resource resource, IFileSystemAccess2 fsa)
}

interface IntermediateGenerator {
	def CharSequence generate(List<Table> tables)
}

interface TableFunctionGenerator {
	def CharSequence generate(List<Pair<Table, TableFunction>> entries)
}