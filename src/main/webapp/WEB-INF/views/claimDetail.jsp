<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fmt" uri="http://java.sun.com/jsp/jstl/fmt" %>
<!DOCTYPE html>
<html>
<head>
    <title>Claim Detail - <c:out value="${formattedClaimReference}"/></title>
</head>
<body>
<h1>Claim Detail</h1>

<section id="claim-summary">
    <h2>Claim <c:out value="${formattedClaimReference}"/></h2>
    <table>
        <tr>
            <th>Claim ID</th>
            <td><c:out value="${claim.claimId}"/></td>
        </tr>
        <tr>
            <th>Reference Code</th>
            <td><c:out value="${formattedClaimReference}"/></td>
        </tr>
        <tr>
            <th>Current Status</th>
            <td><c:out value="${claim.status}"/></td>
        </tr>
        <tr>
            <th>Loss Date</th>
            <td><fmt:formatDate value="${claim.lossDate}" pattern="MM/dd/yyyy"/></td>
        </tr>
        <tr>
            <th>Loss Description</th>
            <td><c:out value="${claim.lossDescription}"/></td>
        </tr>
    </table>
</section>

<section id="status-history">
    <h2>Status History</h2>
    <c:choose>
        <c:when test="${empty statusHistory}">
            <p>No status history available.</p>
        </c:when>
        <c:otherwise>
            <table>
                <thead>
                <tr>
                    <th>Prior Status</th>
                    <th>New Status</th>
                    <th>Changed By</th>
                    <th>Changed At</th>
                    <th>Note</th>
                </tr>
                </thead>
                <tbody>
                <c:forEach var="history" items="${statusHistory}">
                    <tr>
                        <td><c:out value="${history.priorStatus}"/></td>
                        <td><c:out value="${history.newStatus}"/></td>
                        <td><c:out value="${history.changedBy}"/></td>
                        <td><fmt:formatDate value="${history.changedAt}" pattern="MM/dd/yyyy HH:mm"/></td>
                        <td><c:out value="${history.note}"/></td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </c:otherwise>
    </c:choose>
</section>

<section id="damage-assessments">
    <h2>Damage Assessments</h2>
    <c:choose>
        <c:when test="${empty damageAssessments}">
            <p>No damage assessments recorded.</p>
        </c:when>
        <c:otherwise>
            <table>
                <thead>
                <tr>
                    <th>Description</th>
                    <th>Estimated Cost</th>
                    <th>Assessment Date</th>
                </tr>
                </thead>
                <tbody>
                <c:forEach var="assessment" items="${damageAssessments}">
                    <tr>
                        <td><c:out value="${assessment.description}"/></td>
                        <td><fmt:formatNumber value="${assessment.estimatedCost}" type="currency"/></td>
                        <td><fmt:formatDate value="${assessment.assessmentDate}" pattern="MM/dd/yyyy"/></td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </c:otherwise>
    </c:choose>
</section>

<section id="reserve">
    <h2>Reserve</h2>
    <c:choose>
        <c:when test="${empty reserve}">
            <p>No reserve has been set for this claim.</p>
        </c:when>
        <c:otherwise>
            <p>Current Amount: <fmt:formatNumber value="${reserve.currentAmount}" type="currency"/></p>
            <p>Recommended Amount: <fmt:formatNumber value="${reserve.recommendedAmount}" type="currency"/></p>
        </c:otherwise>
    </c:choose>

    <h3>Reserve History</h3>
    <c:choose>
        <c:when test="${empty reserveHistory}">
            <p>No reserve history available.</p>
        </c:when>
        <c:otherwise>
            <table>
                <thead>
                <tr>
                    <th>Prior Amount</th>
                    <th>New Amount</th>
                    <th>Reason</th>
                    <th>Changed By</th>
                    <th>Changed At</th>
                </tr>
                </thead>
                <tbody>
                <c:forEach var="rh" items="${reserveHistory}">
                    <tr>
                        <td><fmt:formatNumber value="${rh.priorAmount}" type="currency"/></td>
                        <td><fmt:formatNumber value="${rh.newAmount}" type="currency"/></td>
                        <td><c:out value="${rh.reason}"/></td>
                        <td><c:out value="${rh.changedBy}"/></td>
                        <td><fmt:formatDate value="${rh.changedAt}" pattern="MM/dd/yyyy HH:mm"/></td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </c:otherwise>
    </c:choose>
</section>

<section id="documents">
    <h2>Documents</h2>
    <c:choose>
        <c:when test="${empty documents}">
            <p>No documents attached.</p>
        </c:when>
        <c:otherwise>
            <table>
                <thead>
                <tr>
                    <th>File Name</th>
                    <th>Document Type</th>
                    <th>File Size (bytes)</th>
                </tr>
                </thead>
                <tbody>
                <c:forEach var="doc" items="${documents}">
                    <tr>
                        <td><c:out value="${doc.fileName}"/></td>
                        <td><c:out value="${doc.documentType}"/></td>
                        <td><c:out value="${doc.fileSizeBytes}"/></td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </c:otherwise>
    </c:choose>
</section>

<c:if test="${not empty litigationRecords}">
    <section id="litigation-records">
        <h2>Litigation Records</h2>
        <table>
            <thead>
            <tr>
                <th>Case Reference</th>
                <th>Filing Date</th>
                <th>Status</th>
                <th>Attorney Name</th>
            </tr>
            </thead>
            <tbody>
            <c:forEach var="lit" items="${litigationRecords}">
                <tr>
                    <td><c:out value="${lit.caseReference}"/></td>
                    <td><fmt:formatDate value="${lit.filingDate}" pattern="MM/dd/yyyy"/></td>
                    <td><c:out value="${lit.status}"/></td>
                    <td><c:out value="${lit.attorneyName}"/></td>
                </tr>
            </c:forEach>
            </tbody>
        </table>
    </section>
</c:if>

</body>
</html>
