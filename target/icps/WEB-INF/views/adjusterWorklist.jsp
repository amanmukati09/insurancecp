<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html>
<head>
    <title>Adjuster Worklist</title>
</head>
<body>
<c:choose>
    <c:when test="${adjusterNotFound}">
        <h1>Adjuster Worklist</h1>
        <p>No adjuster found for the requested id.</p>
    </c:when>
    <c:otherwise>
        <h1>Worklist for <c:out value="${adjuster.firstName}"/> <c:out value="${adjuster.lastName}"/></h1>
    </c:otherwise>
</c:choose>
<section id="worklist-claims">
    <c:choose>
        <c:when test="${empty worklistClaims}">
            <p>No claims currently assigned</p>
        </c:when>
        <c:otherwise>
            <table>
                <tr>
                    <th>Claim ID</th>
                    <th>Claimant ID</th>
                    <th>Policy Reference ID</th>
                    <th>Loss Date</th>
                    <th>Loss Description</th>
                    <th>Status</th>
                    <th>Under Fraud Review</th>
                    <th>Net Paid Amount</th>
                    <th>Claim Age (days)</th>
                </tr>
                <c:forEach var="worklistClaim" items="${worklistClaims}">
                    <tr>
                        <td><a href="${pageContext.request.contextPath}/claims/${worklistClaim.claim_id}"><c:out value="${worklistClaim.claim_id}"/></a></td>
                        <td><c:out value="${worklistClaim.claimant_id}"/></td>
                        <td><c:out value="${worklistClaim.policy_reference_id}"/></td>
                        <td><fmt:formatDate value="${worklistClaim.loss_date}" pattern="MM/dd/yyyy"/></td>
                        <td><c:out value="${worklistClaim.loss_description}"/></td>
                        <td><c:out value="${worklistClaim.status}"/></td>
                        <td><c:out value="${worklistClaim.under_fraud_review}"/></td>
                        <td><c:out value="${worklistClaim.net_paid_amount}"/></td>
                        <td><c:out value="${worklistClaim.claim_age_days}"/></td>
                    </tr>
                </c:forEach>
            </table>
        </c:otherwise>
    </c:choose>
</section>
</body>
</html>
