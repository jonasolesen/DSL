package dk.sdu.mmmi.validation

import dk.sdu.mmmi.typescriptdsl.Attribute
import dk.sdu.mmmi.typescriptdsl.FunctionCreate
import dk.sdu.mmmi.typescriptdsl.FunctionCreateParameter
import dk.sdu.mmmi.typescriptdsl.FunctionReadParameter
import dk.sdu.mmmi.typescriptdsl.FunctionSelect
import dk.sdu.mmmi.typescriptdsl.FunctionWriteParameter
import dk.sdu.mmmi.typescriptdsl.Table
import java.util.List
import java.util.Set
import org.eclipse.xtext.validation.Check

import static dk.sdu.mmmi.generator.Helpers.*
import static dk.sdu.mmmi.typescriptdsl.TypescriptdslPackage.Literals.*
import static org.eclipse.xtext.EcoreUtil2.*

class FunctionValidator extends AbstractTypescriptdslValidator {

	@Check
	def validateFunctionSelect(FunctionSelect select) {
		val duplicates = select.attributes.duplicates

		if (duplicates.length > 0) {
			error('''Each attribute can only appear in select statements once. Duplicates: «duplicates.names»''',
				FUNCTION_SELECT__ATTRIBUTES)
		}
	}

	@Check
	def validateFunctionRead(FunctionReadParameter read) {
		val attributes = read.parameters.map [
			if(attribute !== null) return attribute
			if(constraint.left !== null) return constraint.left
		]

		val duplicates = attributes.duplicates

		if (duplicates.length > 0) {
			error('''Each attribute can only appear in where statements once. Duplicates: «duplicates.names»''',
				FUNCTION_READ_PARAMETER__PARAMETERS)
		}
	}

	@Check
	def validateFunctionWrite(FunctionWriteParameter write) {
		val attributes = write.records.map[key]

		val duplicates = attributes.duplicates

		if (duplicates.length > 0) {
			error('''Each attribute can only appear in update statements once. Duplicates: «duplicates.names»''',
				FUNCTION_WRITE_PARAMETER__RECORDS)
		}
	}

	@Check
	def validateFunctionCreate(FunctionCreateParameter create) {
		val function = getContainerOfType(create, FunctionCreate)

		val attributes = create.parameters.map [
			if(attribute !== null) return attribute
			if(record !== null) return record.key
		]

		val duplicates = attributes.duplicates

		if (duplicates.length > 0) {
			error('''Each attribute can only appear in create statements once. Duplicates: «duplicates.names»''',
				FUNCTION_CREATE_PARAMETER__PARAMETERS)
		}

		function.validateCreateRecords(attributes)
	}

	def validateCreateRecords(FunctionCreate function, List<Attribute> attributes) {
		val table = getContainerOfType(function, Table)

		if(table === null) return
		val required = scalars(table.attributes.filter[!optional].toList, true)
		val missing = required.filter[!attributes.contains(it)]

		if (missing.length > 0) {
			error('''Create statements must contain all required attributes. Missing: «missing.names»''',
				FUNCTION_CREATE_PARAMETER__PARAMETERS)
		}
	}

	def duplicates(List<Attribute> attributes) {
		val Set<Attribute> attributeSet = newHashSet()

		attributes.filter[!attributeSet.add(it)].toList.reverseView
	}

	def names(Iterable<Attribute> attributes) {
		attributes.map[name].join(', ')
	}
}
