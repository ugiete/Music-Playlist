import { useState } from "react";
import DeleteIconButton from "../../../../components/button/delete/delete-icon-button";
import EditIconButton from "../../../../components/button/edit/edit-icon-button";
import TextualLogo from "../../../../components/logo/textual/logo-textual";
import PlanModel from "../../../../models/plan";
import './admin-plans-list-page.css'

function AdminPlansListPage() {
    const [currentPage, setCurrentPage] = useState(1);
    const [lastPage, setLastPage] = useState(10);
    const [pageOptions, setPageOptions] = useState([1, 2, 3, 4, 5]);

    const plans: PlanModel[] = [
        new PlanModel('Gold', true),
        new PlanModel('Basic', false),
    ];

    function pageForward() {
        if (currentPage < lastPage) {
            if (pageOptions[pageOptions.length - 1] < lastPage) {
                const options = pageOptions;
                options.push(pageOptions[pageOptions.length - 1] + 1);
                options.shift();
                setPageOptions(options);
            }
            
            setCurrentPage(currentPage + 1);
        }
    }
    
    function pageBackward() {
        if (currentPage > 1) {
            if (pageOptions[0] > 1) {
                const options = pageOptions;
                options.unshift(pageOptions[0] - 1);
                options.pop();
                setPageOptions(options);
            }

            setCurrentPage(currentPage - 1);
        }
    }

    function selectPage(page: number) {
        setCurrentPage(page);
    }

    function deletePlan(plan: PlanModel) {
        console.log(plan.getName());
    }

    return (
        <div className="adminPlans">
            <header className='adminNavbar'>
                <TextualLogo fontSize={28} />
                <div className="navbarMenu">
                    <a href="clients"><h4>Clients</h4></a>
                    <a href="musics"><h4>Musics</h4></a>
                    <h4>Plans</h4>
                </div>
            </header>
            <div className="adminPlansBody">
                <div className="adminPlansCard">
                    <div id="adminPlansHeader">
                        <h1>List Plans</h1>
                        <button>NEW +</button>
                    </div>

                    <table className="plansTable">
                        <thead>
                            <tr>
                                <th></th>
                                <th></th>
                                <th>Name</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>

                            {
                                plans.map((plan: PlanModel) => {
                                    return (
                                        <tr>
                                            <td className="plansActionColumn">
                                                <EditIconButton size={40} />
                                            </td>
                                            <td className="plansActionColumn">
                                                <DeleteIconButton size={40} onClick={() => deletePlan(plan)}/>
                                            </td>
                                            <td>{ plan.getName() }</td>
                                            <td style={{width: '120px'}}>{ plan.getStatus() ? 'Active' : 'Inactive' }</td>
                                        </tr>
                                    );
                                })
                            }
                            
                        </tbody>
                    </table>

                    <div className="pagination">
                        <div className='paginationContainer' >
                            <ul className="paginationMenu">
                                <li onClick={pageBackward}>
                                    <span>{'<'}</span>
                                </li>

                                {
                                    pageOptions.map((page: number) => {
                                        if (page === currentPage) {
                                            return (
                                                <li className="currentPage">
                                                    <span>{currentPage}</span>
                                                </li>
                                            );
                                        }
                                        
                                        return (
                                            <li onClick={() => selectPage(page)}>
                                                <span>{page}</span>
                                            </li>
                                        );
                                    })
                                }

                                <li onClick={pageForward}>
                                    <span>{'>'}</span>
                                </li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    )
}

export default AdminPlansListPage;