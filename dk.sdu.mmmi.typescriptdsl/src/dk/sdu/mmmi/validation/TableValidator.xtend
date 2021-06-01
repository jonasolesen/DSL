package dk.sdu.mmmi.validation

import dk.sdu.mmmi.typescriptdsl.Add
import dk.sdu.mmmi.typescriptdsl.And
import dk.sdu.mmmi.typescriptdsl.Attribute
import dk.sdu.mmmi.typescriptdsl.BoolType
import dk.sdu.mmmi.typescriptdsl.Comparison
import dk.sdu.mmmi.typescriptdsl.Constraint
import dk.sdu.mmmi.typescriptdsl.Contains
import dk.sdu.mmmi.typescriptdsl.Div
import dk.sdu.mmmi.typescriptdsl.Expression
import dk.sdu.mmmi.typescriptdsl.Field
import dk.sdu.mmmi.typescriptdsl.IntType
import dk.sdu.mmmi.typescriptdsl.Mul
import dk.sdu.mmmi.typescriptdsl.Or
import dk.sdu.mmmi.typescriptdsl.Parenthesis
import dk.sdu.mmmi.typescriptdsl.StringType
import dk.sdu.mmmi.typescriptdsl.Sub
import dk.sdu.mmmi.typescriptdsl.Table
import dk.sdu.mmmi.typescriptdsl.TypescriptdslPackage
import java.util.List
import org.eclipse.xtext.validation.Check

import static dk.sdu.mmmi.validation.Helpers.*
import static org.eclipse.xtext.EcoreUtil2.*

import static extension dk.sdu.mmmi.generator.Helpers.*

class TableValidator extends AbstractTypescriptdslValidator {

	@Check
	def validateField(Field field) {
		val comparison = getContainerOfType(field, Comparison)
		val isIntOperator = switch comparison.operator {
			Contains: false
			default: true
		}

		if (comparison !== null) {
			val isValid = switch field.attribute.type {
				IntType: validateInt(comparison.operator)
				StringType: validateString(comparison.operator)
				BoolType: validateString(comparison.operator)
				default: true
			}

			if (!isValid)
				error('''Invalid operator.''', TypescriptdslPackage.Literals.FIELD__ATTRIBUTE)
		}

		if (isIntOperator && !(field.attribute.type instanceof IntType))
			error('''Attribute «field.attribute.name» is not of type int''',
				TypescriptdslPackage.Literals.FIELD__ATTRIBUTE)
	}

	@Check
	def validateConstraint(Attribute attribute) {
		val List<Comparison> comparisons = attribute.constraint.extractListOfCompareConstraints(newArrayList)

		comparisons.forEach [
			val list = countFields
			if (!list.get(0).forall[!list.get(1).contains(it)]) {
				error('Attribute name is the same as on the left side', it,
					TypescriptdslPackage.Literals.COMPARISON__RIGHT)
			}
		]
	}

	@Check
	def validatePrimary(Table table) {
		val primaryKeys = table.attributes.primaryKeys

		if (table.superType !== null && primaryKeys.length > 0) {
			table.superType.extractSuperAttributes(newArrayList()).primaryKeys.forEach [ primary |
				if (table.attributes.primaryKeys.exists[name === primary.name]) {
					error('''Table «table.name» conflicts with a primary key in super table.''',
						TypescriptdslPackage.Literals.TABLE__NAME)
				}
			]
		}

		if (table.extractSuperAttributes(newArrayList()).primaryKeys.empty) {
			error('''Table «table.name» does not contain a primary key.''', TypescriptdslPackage.Literals.TABLE__NAME)
		}

		if (primaryKeys.length > 1) {
			error('''Table «table.name» contains more than one primary key.''',
				TypescriptdslPackage.Literals.TABLE__NAME)
		}
	}

	def List<Comparison> extractListOfCompareConstraints(Constraint con, List<Comparison> list) {
		switch con {
			Or: {
				con.left.extractListOfCompareConstraints(list)
				con.right.extractListOfCompareConstraints(list)
			}
			And: {
				con.left.extractListOfCompareConstraints(list)
				con.right.extractListOfCompareConstraints(list)
			}
			Comparison:
				list.add(con)
		}

		list
	}

	def countFields(Comparison con) {
		val List<String> left = newArrayList()
		val List<String> right = newArrayList()
		con.left.extractFields(left)
		con.right.extractFields(right)
		return #[left, right]
	}

	def void extractFields(Expression exp, List<String> list) {
		switch exp {
			Add: {
				exp.left.extractFields(list);
				exp.right.extractFields(list)
			}
			Sub: {
				exp.left.extractFields(list);
				exp.right.extractFields(list)
			}
			Mul: {
				exp.left.extractFields(list);
				exp.right.extractFields(list)
			}
			Div: {
				exp.left.extractFields(list);
				exp.right.extractFields(list)
			}
			Parenthesis:
				exp.exp.extractFields(list)
			Field:
				list.add(exp.attribute.name)
		}
	}
}
