package dk.sdu.mmmi.generator

import dk.sdu.mmmi.typescriptdsl.Table
import java.util.ArrayList
import dk.sdu.mmmi.typescriptdsl.IntType
import dk.sdu.mmmi.typescriptdsl.StringType
import dk.sdu.mmmi.typescriptdsl.DateType
import dk.sdu.mmmi.typescriptdsl.AttributeType
import dk.sdu.mmmi.typescriptdsl.Constraint
import dk.sdu.mmmi.typescriptdsl.Comparison
import dk.sdu.mmmi.typescriptdsl.Gte
import dk.sdu.mmmi.typescriptdsl.Gt
import dk.sdu.mmmi.typescriptdsl.Lt
import dk.sdu.mmmi.typescriptdsl.Lte
import dk.sdu.mmmi.typescriptdsl.Equals

class Helpers {

	/**
	 * Handle conversion from Pascal and Snake case
	 */
	static def toCamelCase(String input) {
		if(input === null || input.length == 0) return input

		if (input.contains('_')) {
			val words = input.split('_')
			return words.map[it.toFirstUpper].join.toFirstLower
		}
		return input.toFirstLower
	}

	/**
	 * Handle conversion from Camel and Snake case
	 */
	static def toPascalCase(String input) {
		if(input === null || input.length == 0) return input

		if (input.contains('_')) {
			val words = input.split('_')
			return words.map[it.toFirstUpper].join
		}
		return input.toFirstUpper
	}

	/**
	 * Handle conversion from Pascal and Camel case
	 */
	static def toSnakeCase(String input) {
		if(input === null || input.length == 0) return input
		val firstLower = input.toFirstLower

		var start = 0
		var words = new ArrayList<String>()

		for (var i = 0; i < firstLower.length; i++) {
			if (Character.isUpperCase(firstLower.charAt(i))) {
				words.add(firstLower.substring(start, i).toFirstLower)
				start = i
			}
		}
		words.add(firstLower.substring(start).toFirstLower)
		return words.join('_')
	}

	static def getPrimaryKey(Table table) {
		val primaries = table.attributes.filter[it.primary]
		if(primaries.size == 0) throw new Exception('''No primary key for table «table.name»''')
		if(primaries.size > 1) throw new Exception('''Only one primary key can be defined for «table.name»''')
		primaries.head
	}
	
	static def asString(AttributeType type) {
		switch type {
			IntType: 'number'
			StringType: 'string'
			DateType: 'Date'
			default: 'unknown'
		}
	}
	
//	static def asPrismaObject(Condition constraint) {
//		if (constraint)
//		val operator = switch constraint.left {
//			Gt: 'gt'
//			Gte: 'gte'
//			Lt: 'lt'
//			Lte: 'lte'
//			Equals: 'equals'
//			Contains:
//		}
//	}
}
